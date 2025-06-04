// frontend/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // pour kIsWeb
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'src/services/auth_service.dart';
import 'src/services/user_service.dart';
import 'src/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NE PLUS CHARGER AUCUN .env EN WEB
  if (!kIsWeb) {
    // Sur mobile/desktop : on peut charger un .env local (à placer à la racine)
    try {
      await dotenv.load(fileName: ".env");
      debugPrint("✅ .env local chargé");
    } catch (e) {
      debugPrint("⚠️ Pas de fichier .env local : $e");
    }
  } else {
    // Sur Web : on ne charge rien (évite l'erreur 404)
    debugPrint("ℹ️ Mode Web détecté : pas de chargement de .env");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ProxyProvider<AuthService, UserService>(
          update: (_, authService, __) => UserService(authService),
        ),
      ],
      child: MaterialApp(
        title: 'ArtFans App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
