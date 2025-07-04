// lib/src/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/add_content_screen.dart';
import '../screens/admin_home_screen.dart';
import '../screens/my_contents_screen.dart';
import '../screens/edit_content_screen.dart';
import '../screens/feed_screen.dart';

import '../../main.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userProv = context.read<UserProvider>();

    return GoRouter(
      initialLocation: '/login',
      refreshListenable: Listenable.merge([auth, userProv]),
      observers: [routeObserver],

      redirect: (BuildContext _, GoRouterState state) {
        final loggedIn = auth.status == AuthStatus.authenticated;
        final loggingIn = state.uri.toString() == '/login';
        final registering = state.uri.toString() == '/register';
        final goingToAdmin = state.uri.toString() == '/admin';

        if (!loggedIn && !loggingIn && !registering) {
          return '/login';
        }
        if (loggedIn && (loggingIn || registering)) {
          return '/home';
        }
        final role = userProv.user?['Role'] as String?;
        if (goingToAdmin && role != 'admin') {
          return '/home';
        }
        return null;
      },

      routes: <GoRoute>[
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const FeedScreen(),
        ),

        GoRoute(
          path: '/add-content',
          name: 'add_content',
          builder: (context, state) => const AddContentScreen(),
        ),
        GoRoute(
          path: '/admin',
          name: 'admin',
          builder: (context, state) => const AdminHomeScreen(),
        ),
        GoRoute(
          path: "/my-contents",
          builder: (context, state) => const MyContentsScreen(),
        ),
        GoRoute(
          path: '/edit-content/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return EditContentScreen(contentId: id);
          },
        ),
      ],
    );
  }
}
