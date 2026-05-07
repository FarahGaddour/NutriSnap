import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _apiKey = 'UAmoza9FE9g4YeYvnu2AdZland6m46RNB0kpif7s';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _products = [];
  bool _isLoading = false;
  String _erreur = '';

  Future<void> _rechercher(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isLoading = true; _products = []; _erreur = ''; });

    try {
      final url = Uri.parse(
          'https://api.nal.usda.gov/fdc/v1/foods/search?query=$query&pageSize=10&api_key=$_apiKey');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foods = data['foods'] as List? ?? [];
        setState(() {
          _products = foods;
          _isLoading = false;
          if (foods.isEmpty) _erreur = 'Aucun produit trouvé pour "$query"';
        });
      } else {
        setState(() { _erreur = 'Erreur serveur : ${response.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _erreur = 'Erreur de connexion.'; _isLoading = false; });
    }
  }

  Map<String, String> _extractNutrition(Map<String, dynamic> food) {
    final nutrients = food['foodNutrients'] as List? ?? [];
    String getVal(String name) {
      final n = nutrients.firstWhere(
              (n) => n['nutrientName']?.toString().contains(name) == true, orElse: () => {});
      return n['value']?.toString() ?? 'N/A';
    }
    return {
      'nom': food['description'] ?? 'Inconnu',
      'calories': getVal('Energy'),
      'proteines': getVal('Protein'),
      'glucides': getVal('Carbohydrate'),
      'lipides': getVal('Total lipid'),
      'fibres': getVal('Fiber'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rechercher un aliment'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextField(
              controller: _controller,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Ex: banana, pizza, chicken...',
                hintStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF2E7D32)),
                  onPressed: () => _rechercher(_controller.text),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: _rechercher,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading) const CircularProgressIndicator(color: Color(0xFF2E7D32)),
          if (_erreur.isNotEmpty && _products.isEmpty)
            Text(_erreur, style: const TextStyle(color: Colors.red)),
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final food = _products[index];
                final name = food['description']?.toString() ?? '';
                final nutrients = food['foodNutrients'] as List? ?? [];
                final calNutrient = nutrients.firstWhere(
                        (n) => n['nutrientName']?.toString().contains('Energy') == true, orElse: () => {});
                final calories = calNutrient['value']?.toString() ?? 'N/A';
                if (name.trim().isEmpty) return const SizedBox();
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ProductDetailPage(nutrition: _extractNutrition(food)),
                  )),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fastfood, color: Color(0xFF2E7D32), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('$calories kcal / 100g', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ])),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  final Map<String, String> nutrition;
  const ProductDetailPage({super.key, required this.nutrition});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  void initState() {
    super.initState();
    _sauvegarder();
  }

  Future<void> _sauvegarder() async {
    final prefs = await SharedPreferences.getInstance();
    final historique = prefs.getStringList('historique') ?? [];
    historique.insert(0,
        '[SEARCH] ${widget.nutrition['nom']} | ${widget.nutrition['calories']} kcal | ${widget.nutrition['proteines']}g prot');
    if (historique.length > 50) historique.removeLast();
    await prefs.setStringList('historique', historique);
  }

  Widget _buildRow(IconData icon, String label, String valeur, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        Text(valeur, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.nutrition;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(n['nom'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            height: 180, width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.fastfood, size: 80, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 20),
          Text(n['nom'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.bar_chart, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                const Text('Valeurs nutritionnelles / 100g',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E7D32))),
              ]),
              const Divider(height: 24),
              _buildRow(Icons.local_fire_department, 'Calories', '${n['calories']} kcal', Colors.orange),
              _buildRow(Icons.fitness_center, 'Protéines', '${n['proteines']} g', const Color(0xFF2E7D32)),
              _buildRow(Icons.grain, 'Glucides', '${n['glucides']} g', const Color(0xFFF9A825)),
              _buildRow(Icons.opacity, 'Lipides', '${n['lipides']} g', const Color(0xFF66BB6A)),
              _buildRow(Icons.grass, 'Fibres', '${n['fibres']} g', const Color(0xFF2E7D32)),
            ]),
          ),
        ]),
      ),
    );
  }
}