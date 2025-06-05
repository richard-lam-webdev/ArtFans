import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'src/services/auth_service.dart';
import 'src/services/user_service.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/home_screen.dart'; 
import 'src/screens/add_content_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/add-content',
      builder: (context, state) => const AddContentScreen(),
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
      debugPrint("✅ .env local chargé");
    } catch (e) {
      debugPrint("⚠️ Pas de fichier .env local : $e");
    }
  } else {
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
      child: MaterialApp.router(
        title: 'ArtFans App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: _router, // ← ici la config go_router !
      ),
    );
  }
}
