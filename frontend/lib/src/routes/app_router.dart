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
import '../screens/conversations_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/my_subscriptions_screen.dart';
import '../screens/splash_screen.dart'; 

import '../../main.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userProv = context.read<UserProvider>();

    return GoRouter(
      initialLocation: '/splash', 
      refreshListenable: Listenable.merge([auth, userProv]),
      observers: [routeObserver],

      redirect: (BuildContext _, GoRouterState state) {
        final isAuthenticated = auth.status == AuthStatus.authenticated;
        final isLoading = auth.status == AuthStatus.loading;
        final isInitialized = auth.isInitialized;
        
        final currentPath = state.uri.toString();

        if (!isInitialized || isLoading) {
          if (currentPath != '/splash') {
            return '/splash';
          }
          return null;
        }

        final loggingIn = currentPath == '/login';
        final registering = currentPath == '/register';
        final goingToAdmin = currentPath == '/admin';
        final onSplash = currentPath == '/splash';

        // ✨ Si on est sur le splash et initialisé, rediriger selon l'état
        if (onSplash && isInitialized) {
          return isAuthenticated ? '/home' : '/login';
        }

        if (!isAuthenticated && !loggingIn && !registering && !onSplash) {
          return '/login';
        }
        
        if (isAuthenticated && (loggingIn || registering)) {
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
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
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
          path: "/my-subscriptions",
          name: 'my_subscriptions',
          builder: (context, state) => const MySubscriptionsScreen(),
        ),
        GoRoute(
          path: '/messages',
          name: 'messages',
          builder: (context, state) => const ConversationsScreen(),
        ),
        GoRoute(
          path: '/chat/:userId',
          name: 'chat',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            final userName = state.extra as String? ?? 'Utilisateur';
            return ChatScreen(
              otherUserId: userId,
              otherUserName: userName,
            );
          },
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