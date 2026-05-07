import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  List<String> _historique = [];
  String _filtre = 'Tous';

  @override
  void initState() {
    super.initState();
    _chargerHistorique();
  }

  Future<void> _chargerHistorique() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _historique = prefs.getStringList('historique') ?? []; });
  }

  Future<void> _viderHistorique() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('historique');
    setState(() => _historique = []);
  }

  List<String> get _filteredHistorique {
    if (_filtre == 'Tous') return _historique;
    if (_filtre == 'Photo') return _historique.where((e) => !e.startsWith('[BARCODE]') && !e.startsWith('[SEARCH]')).toList();
    if (_filtre == 'Barcode') return _historique.where((e) => e.startsWith('[BARCODE]')).toList();
    if (_filtre == 'Recherche') return _historique.where((e) => e.startsWith('[SEARCH]')).toList();
    return _historique;
  }

  Color _getColor(String item) {
    if (item.startsWith('[BARCODE]')) return const Color(0xFF1565C0);
    if (item.startsWith('[SEARCH]')) return const Color(0xFFE65100);
    return const Color(0xFF2E7D32);
  }

  IconData _getIcon(String item) {
    if (item.startsWith('[BARCODE]')) return Icons.qr_code;
    if (item.startsWith('[SEARCH]')) return Icons.search;
    return Icons.camera_alt;
  }

  String _getLabel(String item) {
    if (item.startsWith('[BARCODE]')) return 'Code-barres';
    if (item.startsWith('[SEARCH]')) return 'Recherche';
    return 'Photo';
  }

  String _getNom(String item) => item.replaceAll('[BARCODE] ', '').replaceAll('[SEARCH] ', '').split('|')[0].trim();
  String _getCalories(String item) { final p = item.split('|'); return p.length >= 2 ? p[1].trim() : ''; }
  String _getProteines(String item) { final p = item.split('|'); return p.length >= 3 ? p[2].trim() : ''; }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Historique'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _historique.isEmpty ? null : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Vider l\'historique ?'),
                  content: const Text('Tous les scans seront supprimés.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) _viderHistorique();
            },
          ),
        ],
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF2E7D32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Total', _historique.length.toString(), Icons.list),
              _statItem('Photos', _historique.where((e) => !e.startsWith('[BARCODE]') && !e.startsWith('[SEARCH]')).length.toString(), Icons.camera_alt),
              _statItem('Barcodes', _historique.where((e) => e.startsWith('[BARCODE]')).length.toString(), Icons.qr_code),
              _statItem('Recherches', _historique.where((e) => e.startsWith('[SEARCH]')).length.toString(), Icons.search),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).cardColor,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Tous', 'Photo', 'Barcode', 'Recherche'].map((f) => GestureDetector(
                onTap: () => setState(() => _filtre = f),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _filtre == f ? const Color(0xFF2E7D32) : Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(f, style: TextStyle(
                      color: _filtre == f ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              )).toList(),
            ),
          ),
        ),
        Expanded(
          child: _filteredHistorique.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.history, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(_historique.isEmpty ? 'Aucun scan enregistré' : 'Aucun résultat pour "$_filtre"',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
          ]))
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredHistorique.length,
            itemBuilder: (context, index) {
              final item = _filteredHistorique[index];
              final color = _getColor(item);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(_getIcon(item), color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_getNom(item), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(_getLabel(item), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Text(_getCalories(item), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
                    if (_getProteines(item).isNotEmpty)
                      Text(_getProteines(item), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ])),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }
}