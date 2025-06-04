// frontend/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'src/services/auth_service.dart';
import 'src/services/user_service.dart';
import 'src/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------
  // Sur Web : on charge le .env depuis assets/.env (VOTRE pubspec.yaml doit
  // avoir "assets: - assets/.env").
  //
  // Sur mobile/desktop (non-Web), on pourra charger depuis racine si
  // nécessaire, mais ici on se concentre sur Web, donc on charge toujours
  // assets/.env.
  // ------------------------------------------------------------------
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    // Si le fichier .env est introuvable ou mal référencé en Web,
    // on affiche simplement un avertissement et on continue.
    debugPrint("⚠️ Impossible de charger assets/.env : $e");
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
