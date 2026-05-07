import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BarcodePage extends StatefulWidget {
  const BarcodePage({super.key});

  @override
  State<BarcodePage> createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  File? _image;
  String _resultat = '';
  bool _isLoading = false;
  Map<String, dynamic>? _nutrition;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _resultat = '';
      _nutrition = null;
      _isLoading = true;
    });

    await _analyserBarcode(File(pickedFile.path));
  }

  Future<void> _analyserBarcode(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final barcodeScanner = BarcodeScanner();
    final List<Barcode> barcodes =
    await barcodeScanner.processImage(inputImage);
    await barcodeScanner.close();

    if (barcodes.isEmpty) {
      setState(() {
        _resultat = 'Aucun code-barres détecté.';
        _isLoading = false;
      });
      return;
    }

    final codeValue = barcodes.first.rawValue ?? '';
    setState(() => _resultat = codeValue);
    await _fetchNutrition(codeValue);
  }

  Future<void> _fetchNutrition(String barcode) async {
    try {
      // D'abord chercher par barcode dans Open Food Facts
      final urlOFF = Uri.parse(
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final responseOFF = await http.get(urlOFF,
        headers: {'User-Agent': 'NutriSnap/1.0 (Flutter; Android)'},
      ).timeout(const Duration(seconds: 8));

      if (responseOFF.statusCode == 200) {
        final data = json.decode(responseOFF.body);
        if (data['status'] == 1) {
          final product = data['product'];
          final nutriments = product['nutriments'] ?? {};
          final nutrition = {
            'nom': product['product_name'] ?? 'Produit inconnu',
            'calories': nutriments['energy-kcal_100g']?.toString() ?? 'N/A',
            'proteines': nutriments['proteins_100g']?.toString() ?? 'N/A',
            'glucides': nutriments['carbohydrates_100g']?.toString() ?? 'N/A',
            'lipides': nutriments['fat_100g']?.toString() ?? 'N/A',
            'fibres': nutriments['fiber_100g']?.toString() ?? 'N/A',
          };
          setState(() {
            _nutrition = nutrition;
            _isLoading = false;
          });
          await _sauvegarder(nutrition);
          return;
        }
      }

      // Fallback : FoodData Central
      final urlFDC = Uri.parse(
          'https://api.nal.usda.gov/fdc/v1/foods/search?query=$barcode&pageSize=1&api_key=UAmoza9FE9g4YeYvnu2AdZland6m46RNB0kpif7s');
      final responseFDC = await http.get(urlFDC).timeout(const Duration(seconds: 10));

      if (responseFDC.statusCode == 200) {
        final data = json.decode(responseFDC.body);
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
            'nom': food['description'] ?? 'Produit inconnu',
            'calories': getVal('Energy'),
            'proteines': getVal('Protein'),
            'glucides': getVal('Carbohydrate'),
            'lipides': getVal('Total lipid'),
            'fibres': getVal('Fiber'),
          };
          setState(() {
            _nutrition = nutrition;
            _isLoading = false;
          });
          await _sauvegarder(nutrition);
        } else {
          setState(() {
            _resultat = 'Produit non trouvé. Code : $barcode';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _resultat = 'Erreur de connexion.';
        _isLoading = false;
      });
    }
  }

  Future<void> _sauvegarder(Map<String, dynamic> nutrition) async {
    final prefs = await SharedPreferences.getInstance();
    final historique = prefs.getStringList('historique') ?? [];
    historique.insert(0,
        '[BARCODE] ${nutrition['nom']} | ${nutrition['calories']} kcal | ${nutrition['proteines']}g prot');
    if (historique.length > 50) historique.removeLast();
    await prefs.setStringList('historique', historique);
  }

  Widget _buildRow(IconData icon, String label, String valeur, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text('$label : ',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(valeur, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Scanner Code-barres'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Caméra'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66BB6A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_image!, height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  SizedBox(height: 8),
                  Text('Recherche des infos nutritionnelles...'),
                ],
              ),
            if (_resultat.isNotEmpty && _nutrition == null && !_isLoading)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_resultat,
                    style: const TextStyle(color: Colors.red)),
              ),
            if (_nutrition != null && !_isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bar_chart, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_nutrition!['nom'],
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32))),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    const Text('Valeurs nutritionnelles pour 100g',
                        style:
                        TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    _buildRow(Icons.local_fire_department, 'Calories',
                        '${_nutrition!['calories']} kcal', Colors.orange),
                    _buildRow(Icons.fitness_center, 'Protéines',
                        '${_nutrition!['proteines']} g',
                        const Color(0xFF2E7D32)),
                    _buildRow(Icons.grain, 'Glucides',
                        '${_nutrition!['glucides']} g',
                        const Color(0xFFF9A825)),
                    _buildRow(Icons.opacity, 'Lipides',
                        '${_nutrition!['lipides']} g',
                        const Color(0xFF66BB6A)),
                    _buildRow(Icons.grass, 'Fibres',
                        '${_nutrition!['fibres']} g',
                        const Color(0xFF2E7D32)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}