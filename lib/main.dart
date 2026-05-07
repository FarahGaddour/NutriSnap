import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'pages/home_page.dart';
import 'pages/scan_page.dart';
import 'pages/barcode_page.dart';
import 'pages/historique_page.dart';
import 'pages/apropos_page.dart';
import 'pages/search_page.dart';
import 'pages/auth_page.dart';
import 'pages/parametre_page.dart';

final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.signOut();

  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(
      const InitializationSettings(android: androidSettings));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'NutriSnap',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
                );
              }
              if (snapshot.hasData) return const HomePage();
              return const AuthPage();
            },
          ),
          routes: {
            '/scan': (context) => const ScanPage(),
            '/barcode': (context) => const BarcodePage(),
            '/historique': (context) => const HistoriquePage(),
            '/apropos': (context) => const AProposPage(),
            '/search': (context) => const SearchPage(),
            '/parametres': (context) => const ParametrePage(),
          },
        );
      },
    );
  }
}