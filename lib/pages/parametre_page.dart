import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';
import 'auth_page.dart';

class ParametrePage extends StatefulWidget {
  const ParametrePage({super.key});

  @override
  State<ParametrePage> createState() => _ParametrePageState();
}

class _ParametrePageState extends State<ParametrePage> {
  bool _darkMode = false;
  bool _notifications = false;

  @override
  void initState() {
    super.initState();
    _darkMode = darkModeNotifier.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Mode Sombre', style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: const Text('Changer l\'apparence de l\'application'),
                    secondary: const Icon(Icons.dark_mode, color: Color(0xFF2E7D32)),
                    value: _darkMode,
                    activeColor: const Color(0xFF2E7D32),
                    onChanged: (val) {
                      setState(() => _darkMode = val);
                      darkModeNotifier.value = val;
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: const Text('Recevoir des rappels nutritionnels'),
                    secondary: const Icon(Icons.notifications, color: Color(0xFF2E7D32)),
                    value: _notifications,
                    activeColor: const Color(0xFF2E7D32),
                    onChanged: (val) async {
                      setState(() => _notifications = val);
                      if (val) {
                        await notifications.show(
                          0,
                          'NutriSnap 🥗',
                          'Les notifications sont activées !',
                          const NotificationDetails(
                            android: AndroidNotificationDetails(
                              'nutrisnap_channel',
                              'NutriSnap Notifications',
                              channelDescription: 'Rappels nutritionnels',
                              importance: Importance.high,
                              priority: Priority.high,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Se déconnecter', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthPage()),
                        (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}