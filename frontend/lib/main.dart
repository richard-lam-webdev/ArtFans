import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'src/providers/auth_provider.dart';
import 'src/providers/user_provider.dart';
import 'src/providers/admin_provider.dart';
import 'src/providers/admin_content_provider.dart';
import 'src/providers/theme_provider.dart';
import 'src/services/auth_service.dart';
import 'src/services/user_service.dart';
import 'src/services/admin_content_service.dart';
import 'src/services/admin_service.dart';
import 'src/routes/app_router.dart';
import 'theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'src/providers/message_provider.dart';
import 'src/widgets/app_wrapper.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
      debugPrint("✅ .env local chargé");
    } catch (e) {
      debugPrint("⚠️ Pas de fichier .env local : $e");
    }
  }
    timeago.setLocaleMessages('fr', timeago.FrMessages());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userService = UserService(authService);
    final adminService = AdminService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(userService: userService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(adminService: adminService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminContentProvider(service: AdminContentService()),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: AppWrapper(
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final router = AppRouter.router(context);
          return MaterialApp.router(
            title: 'ArtFans App',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            routerConfig: router,
          );
        },
      ),
      ),
    );
  }
}
