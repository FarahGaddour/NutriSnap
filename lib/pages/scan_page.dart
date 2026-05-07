import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  File? _image;
  bool _isLoading = false;
  String _labelDetecte = '';
  Map<String, dynamic>? _nutrition;
  String _erreur = '';

  final Map<String, String> _labelToQuery = {
    'Pizza': 'pizza', 'Banana': 'banana ', 'Apple': 'apple ',
    'Orange': 'orange raw', 'Tomato': 'tomato raw', 'Cheese': 'cheese',
    'Bread': 'bread', 'Chicken': 'chicken raw', 'Egg': 'egg raw',
    'Rice': 'rice cooked', 'Pasta': 'pasta cooked', 'Salad': 'salad',
    'Hamburger': 'hamburger', 'Sandwich': 'sandwich', 'Cake': 'cake',
    'Ice cream': 'ice cream', 'Coffee': 'coffee', 'Juice': 'orange juice',
    'Lemon': 'lemon raw', 'Strawberry': 'strawberry raw',
    'Watermelon': 'watermelon raw', 'Mango': 'mango raw',
    'Grape': 'grape raw', 'Pineapple': 'pineapple raw',
    'Bird': 'chicken raw', 'Beak': 'chicken raw', 'Rooster': 'chicken raw',
    'Poultry': 'chicken raw', 'Meat': 'beef raw', 'Steak': 'beef steak',
    'Seafood': 'fish raw', 'Fish': 'fish raw', 'Shrimp': 'shrimp raw',
    'Vegetable': 'mixed vegetables', 'Carrot': 'carrot raw',
    'Broccoli': 'broccoli raw', 'Corn': 'corn raw', 'Potato': 'potato raw',
    'Fruit': 'apple raw', 'Berry': 'strawberry raw',
    'Dairy': 'cheese', 'Milk': 'milk', 'Yogurt': 'yogurt',
    'Drink': 'orange juice', 'Beverage': 'orange juice', 'Tea': 'tea',
    'Fast food': 'hamburger', 'Junk food': 'hamburger',
    'Dish': 'pizza', 'Dough': 'pizza', 'Comfort food': 'pizza',
    'Baked goods': 'bread', 'Pastry': 'croissant',
    'Chocolate': 'chocolate', 'Candy': 'candy', 'Cookie': 'cookie',
    'Soup': 'soup', 'Stew': 'beef stew', 'Sauce': 'tomato sauce',
    'Nut': 'almond raw', 'Seed': 'sunflower seeds',
  };

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;
    setState(() {
      _image = File(pickedFile.path);
      _isLoading = true;
      _labelDetecte = '';
      _nutrition = null;
      _erreur = '';
    });
    await _analyser(File(pickedFile.path));
  }

  Future<void> _analyser(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final labeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.3));
    final labels = await labeler.processImage(inputImage);
    await labeler.close();

    if (labels.isEmpty) {
      setState(() { _erreur = 'Aucun aliment détecté.'; _isLoading = false; });
      return;
    }

    final labelsGeneriques = ['Food', 'Product', 'Snack', 'Ingredient',
      'Cuisine', 'Recipe', 'Natural foods', 'Whole food', 'Packaging',
      'Label', 'Brand', 'Space', 'Textile', 'Pattern', 'Design',
      'Art', 'Style', 'Material', 'Tableware', 'Plate', 'Bowl',
      'Table', 'Wood', 'Metal', 'Glass', 'Plastic'];

    final labelsFiltres = labels
        .where((l) => !labelsGeneriques.contains(l.label))
        .toList();

    if (labelsFiltres.isEmpty) {
      setState(() {
        _labelDetecte = labels.first.label;
        _erreur = 'Aliment non identifiable.\nUtilisez la Recherche manuelle ou le Scanner Code-barres.';
        _isLoading = false;
      });
      return;
    }

    // Chercher dans TOUS les labels si un match existe dans la map
    String? mappedQuery;
    String? mappedLabel;
    for (final l in labelsFiltres) {
      if (_labelToQuery.containsKey(l.label)) {
        mappedQuery = _labelToQuery[l.label];
        mappedLabel = l.label;
        break;
      }
    }

    final label = mappedLabel ?? labelsFiltres.first.label;
    final query = mappedQuery ?? label;
    setState(() => _labelDetecte = label);
    await _fetchNutrition(query);
  }

  Future<void> _fetchNutrition(String query, {int tentative = 1}) async {
    if (!mounted) return;
    try {
      final url = Uri.parse(
          'https://api.nal.usda.gov/fdc/v1/foods/search?query=$query&pageSize=1&dataType=Foundation,SR%20Legacy&api_key=UAmoza9FE9g4YeYvnu2AdZland6m46RNB0kpif7s');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foods = data['foods'] as List? ?? [];
        if (foods.isNotEmpty) {
          final food = foods[0];
          final nutrients = food['foodNutrients'] as List? ?? [];
          String getVal(String name) {
            final n = nutrients.firstWhere(
                  (n) => n['nutrientName']?.toString().contains(name) == true,
              orElse: () => {},
            );
            return n['value']?.toString() ?? 'N/A';
          }
          final nutrition = {
            'nom': food['description'] ?? query,
            'calories': getVal('Energy'),
            'proteines': getVal('Protein'),
            'glucides': getVal('Carbohydrate'),
            'lipides': getVal('Total lipid'),
            'fibres': getVal('Fiber'),
          };
          setState(() { _nutrition = nutrition; _isLoading = false; });
          await _sauvegarder(nutrition);
        } else {
          setState(() { _erreur = 'Aucune info trouvée.'; _isLoading = false; });
        }
      } else if (tentative < 4) {
        await Future.delayed(const Duration(seconds: 2));
        await _fetchNutrition(query, tentative: tentative + 1);
      } else {
        setState(() { _erreur = 'Serveur indisponible.'; _isLoading = false; });
      }
    } catch (e) {
      if (tentative < 4) {
        await Future.delayed(const Duration(seconds: 2));
        await _fetchNutrition(query, tentative: tentative + 1);
      } else {
        if (!mounted) return;
        setState(() { _erreur = 'Connexion échouée.'; _isLoading = false; });
      }
    }
  }

  Future<void> _sauvegarder(Map<String, dynamic> nutrition) async {
    final prefs = await SharedPreferences.getInstance();
    final historique = prefs.getStringList('historique') ?? [];
    historique.insert(0,
        '${nutrition['nom']} | ${nutrition['calories']} kcal | ${nutrition['proteines']}g prot');
    if (historique.length > 50) historique.removeLast();
    await prefs.setStringList('historique', historique);
  }

  Widget _buildRow(IconData icon, String label, String valeur, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(valeur, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Scanner un aliment'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Caméra'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _pickImage(ImageSource.camera),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Galerie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _pickImage(ImageSource.gallery),
            )),
          ]),
          const SizedBox(height: 16),
          if (_image != null)
            ClipRRect(borderRadius: BorderRadius.circular(16),
                child: Image.file(_image!, height: 200, fit: BoxFit.cover)),
          const SizedBox(height: 16),
          if (_isLoading) const Column(children: [
            CircularProgressIndicator(color: Color(0xFF2E7D32)),
            SizedBox(height: 8),
            Text('Analyse en cours...'),
          ]),
          if (_labelDetecte.isNotEmpty && !_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Aliment détecté : $_labelDetecte',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ),
          const SizedBox(height: 12),
          if (_erreur.isNotEmpty && !_isLoading)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(child: Text(_erreur, style: const TextStyle(color: Colors.orange))),
              ]),
            ),
          const SizedBox(height: 8),
          if (_nutrition != null && !_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.bar_chart, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_nutrition!['nom'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
                ]),
                const Divider(height: 20),
                const Text('Valeurs nutritionnelles pour 100g', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                _buildRow(Icons.local_fire_department, 'Calories', '${_nutrition!['calories']} kcal', Colors.orange),
                _buildRow(Icons.fitness_center, 'Protéines', '${_nutrition!['proteines']} g', const Color(0xFF2E7D32)),
                _buildRow(Icons.grain, 'Glucides', '${_nutrition!['glucides']} g', const Color(0xFFF9A825)),
                _buildRow(Icons.opacity, 'Lipides', '${_nutrition!['lipides']} g', const Color(0xFF66BB6A)),
                _buildRow(Icons.grass, 'Fibres', '${_nutrition!['fibres']} g', const Color(0xFF2E7D32)),
              ]),
            ),
        ]),
      ),
    );
  }
}