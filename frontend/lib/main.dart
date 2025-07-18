import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/user_provider.dart';
import 'src/providers/admin_provider.dart';
import 'src/providers/admin_content_provider.dart';
import 'src/providers/admin_stats_provider.dart';
import 'src/providers/theme_provider.dart';
import 'src/services/auth_service.dart';
import 'src/services/user_service.dart';
import 'src/services/admin_content_service.dart';
import 'src/services/admin_service.dart';
import 'src/services/admin_stats_service.dart';
import 'src/routes/app_router.dart';
import 'theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'src/providers/message_provider.dart';
import 'src/widgets/app_wrapper.dart';
import 'src/services/subscription_service.dart';
import 'src/providers/subscription_provider.dart';
import 'src/providers/comment_moderation_provider.dart';
import 'src/services/admin_comment_service.dart';
import 'src/providers/content_detail_provider.dart';
import 'src/services/content_service.dart';
import 'src/services/comment_service.dart';
import 'src/providers/feature_flag_provider.dart';
import 'src/services/feature_flag_service.dart';
import 'src/providers/report_provider.dart';
import 'src/services/report_service.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ .env chargé');
  } catch (e) {
    debugPrint('⚠️ Impossible de charger .env : $e');
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
    final adminStatsService = AdminStatsService();
    final subscriptionService = SubscriptionService();
    final contentService = ContentService();
    final commentService = CommentService();

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
        ChangeNotifierProvider(
          create:
              (_) => AdminStatsProvider(adminStatsService: adminStatsService),
        ),
        ChangeNotifierProvider(
          create:
              (_) => SubscriptionProvider(
                subscriptionService: subscriptionService,
              ),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(
          create:
              (_) => CommentModerationProvider(service: AdminCommentService()),
        ),
        ChangeNotifierProvider(
          create:
              (_) => ContentDetailProvider(
                contentService: contentService,
                commentService: commentService,
              ),
        ),
        ChangeNotifierProvider(
          create: (_) => FeatureFlagProvider(service: FeatureFlagService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(reportService: ReportService()),
        ),
      ],
      child: AppWrapper(
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            final router = AppRouter.router(context);
            return MaterialApp.router(
              title: 'ArtFans',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeProvider.themeMode,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}
