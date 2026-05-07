import 'package:flutter/material.dart';
import 'search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'NutriSnap',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
            onPressed: () => Navigator.pushNamed(context, '/apropos'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(

                      radius: 40,
                      backgroundImage: AssetImage('assets/images/profile.png')
                   ,
                  ),
                  SizedBox(height: 12),
                  Text('NutriSnap',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text('Analyse nutritionnelle par IA',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF2E7D32)),
              title: const Text('Accueil'),
              onTap: () => Navigator.pop(context),
            ),
            _drawerItem(context, Icons.search, 'Rechercher', '/search'),
            _drawerItem(context, Icons.camera_alt, 'Scanner aliment', '/scan'),
            _drawerItem(context, Icons.qr_code, 'Scanner code-barres', '/barcode'),
            _drawerItem(context, Icons.history, 'Historique', '/historique'),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF2E7D32)),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/parametres');
              },
            ),ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
            const Divider(),
            _drawerItem(context, Icons.info, 'À propos', '/apropos'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bienvenue ! 👋',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Que voulez-vous\nanalyser aujourd\'hui ?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.emoji_food_beverage, color: Colors.white70),
                      SizedBox(width: 8),
                      Text('Calories • Protéines • Glucides • Lipides',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Barre de recherche
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/search'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF2E7D32)),
                    SizedBox(width: 12),
                    Text('Rechercher un aliment...',
                        style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text('Options',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20))),

            const SizedBox(height: 12),

            // 3 cartes
            Row(
              children: [
                Expanded(
                  child: _optionCard(
                    context,
                    icon: Icons.image_search,
                    label: 'Scanner\nun aliment',
                    color: const Color(0xFF2E7D32),
                    route: '/scan',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _optionCard(
                    context,
                    icon: Icons.qr_code_scanner,
                    label: 'Scanner\ncode-barres',
                    color: const Color(0xFF1565C0),
                    route: '/barcode',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _optionCard(
                    context,
                    icon: Icons.search,
                    label: 'Rechercher\nun produit',
                    color: const Color(0xFFE65100),
                    route: '/search',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Historique rapide
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Historique récent',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20))),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/historique'),
                  child: const Text('Voir tout',
                      style: TextStyle(color: Color(0xFF2E7D32))),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/historique'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.history, color: Color(0xFF2E7D32)),
                    SizedBox(width: 12),
                    Text('Voir l\'historique des scans',
                        style: TextStyle(color: Colors.grey)),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard(BuildContext context,
      {required IconData icon,
        required String label,
        required Color color,
        required String route}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  ListTile _drawerItem(
      BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2E7D32)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}