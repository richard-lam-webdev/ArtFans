// lib/src/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/add_content_screen.dart';

class AppRouter {
  /// Retourne une instance unique de GoRouter
  static GoRouter router(BuildContext context) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: context.read<AuthProvider>(),
      redirect: (BuildContext context, GoRouterState state) {
        final authProvider = context.read<AuthProvider>();
        final isLoggingIn = state.uri.toString() == '/login';
        final isRegistering = state.uri.toString() == '/register';

        // Si on est authentifié, on ne doit pas rester sur /login ou /register
        if (authProvider.status == AuthStatus.authenticated) {
          // Si on tente d’accéder à /login ou /register, rediriger vers /home
          if (isLoggingIn || isRegistering) {
            return '/home';
          }
          // Sinon, on reste sur la route courante (ex. /home)
          return null;
        }

        // Si on n’est pas authentifié et qu’on est sur /home, rediriger vers /login
        if (authProvider.status == AuthStatus.unauthenticated) {
          if (state.uri.toString() == '/home') {
            return '/login';
          }
        }

        // Par défaut, pas de redirection
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
        builder: (context, state) => const AddContentScreen(),
      ),
        // Vous pouvez ajouter d'autres routes protégées ici (ex. /profile, /settings, etc.)
      ],
    );
  }
}
