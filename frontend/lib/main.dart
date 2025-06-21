// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'src/providers/auth_provider.dart';
import 'src/providers/user_provider.dart';
import 'src/providers/admin_provider.dart';
import 'src/providers/admin_content_provider.dart';
import 'src/services/auth_service.dart';
import 'src/services/user_service.dart';
import 'src/services/admin_content_service.dart';
import 'src/services/admin_service.dart';
import 'src/routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
      debugPrint("✅ .env local chargé");
    } catch (e) {
      debugPrint("⚠️ Pas de fichier .env local : $e");
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instanciation des services
    final authService = AuthService();
    final userService = UserService(authService);
    final adminService = AdminService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(userService: userService),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create: (_) => AdminProvider(adminService: adminService),
        ),
        ChangeNotifierProvider<AdminContentProvider>(
          create: (_) => AdminContentProvider(service: AdminContentService()),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Récupérer la configuration du router à partir de AuthProvider
          final router = AppRouter.router(context);
          return MaterialApp.router(
            title: 'ArtFans App',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
