// lib/src/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/add_content_screen.dart';
import '../screens/admin_home_screen.dart';

class AppRouter {
  /// Retourne une instance unique de GoRouter
  static GoRouter router(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userProv = context.read<UserProvider>();

    return GoRouter(
      initialLocation: '/login',
      refreshListenable: Listenable.merge([auth, userProv]),

      redirect: (BuildContext _, GoRouterState state) {
        final loggedIn = auth.status == AuthStatus.authenticated;
        final loggingIn = state.uri.toString() == '/login';
        final registering = state.uri.toString() == '/register';
        final goingToAdmin = state.uri.toString() == '/admin';

        // 1) Non connecté → on force /login (sauf routes login/register)
        if (!loggedIn && !loggingIn && !registering) {
          return '/login';
        }

        // 2) Connecté et sur /login ou /register → on va /home
        if (loggedIn && (loggingIn || registering)) {
          return '/home';
        }

        // 3) Protection de /admin : si on y va sans être admin → /home
        final role = userProv.user?['Role'] as String?;
        if (goingToAdmin && role != 'admin') {
          return '/home';
        }

        // sinon on reste où on est
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
          builder: (context, state) => const HomeScreen(),
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
      ],
    );
  }
}
