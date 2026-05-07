import 'package:flutter/material.dart';

class AProposPage extends StatelessWidget {
  const AProposPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text('NutriSnap',
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Version 1.0.0',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            const Text(
              'Application d\'analyse nutritionnelle basée sur ML Kit et Open Food Facts API.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Développés par :',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Farah Gaddour && Ala Samet  — IIT Sfax',
                style: TextStyle(fontSize: 16, color: Colors.green)),
            const SizedBox(height: 4),
            const Text('Cours : Mobile Programming — 2025/2026',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}