import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/feature_flag_provider.dart';

import '../constants/features.dart';

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
import '../screens/comments_moderation_screen.dart';
import '../screens/content_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/creator_profile_screen.dart'; // 👈 Import du nouvel écran

import '../../main.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userProv = context.read<UserProvider>();
    final flags = context.read<FeatureFlagProvider>();

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: Listenable.merge([auth, userProv, flags]),
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
          path: '/admin/moderation/comments',
          name: 'admin-comments-moderation',
          redirect: (ctx, state) {
            final enabled = ctx.read<FeatureFlagProvider>().features.any(
              (f) => f.key == featureComments && f.enabled,
            );
            return enabled ? null : '/admin';
          },
          builder: (context, state) => const CommentsModerationScreen(),
        ),

        GoRoute(
          path: '/contents/:id',
          name: 'content_detail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ContentDetailScreen(contentId: id);
          },
        ),
        GoRoute(
          path: '/my-contents',
          name: 'my_contents',
          builder: (context, state) => const MyContentsScreen(),
        ),
        GoRoute(
          path: '/my-subscriptions',
          name: 'my_subscriptions',
          builder: (context, state) => const MySubscriptionsScreen(),
        ),

        GoRoute(
          path: '/messages',
          name: 'messages',
          redirect: (ctx, state) {
            final enabled = ctx.read<FeatureFlagProvider>().features.any(
              (f) => f.key == featureChat && f.enabled,
            );
            return enabled ? null : '/home';
          },
          builder: (context, state) => const ConversationsScreen(),
        ),

        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),

        GoRoute(
          path: '/chat/:userId',
          name: 'chat',
          redirect: (ctx, state) {
            final enabled = ctx.read<FeatureFlagProvider>().features.any(
              (f) => f.key == featureChat && f.enabled,
            );
            return enabled ? null : '/home';
          },
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            final userName = state.extra as String? ?? 'Utilisateur';
            return ChatScreen(otherUserId: userId, otherUserName: userName);
          },
        ),

        GoRoute(
          path: '/edit-content/:id',
          name: 'edit_content',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return EditContentScreen(contentId: id);
          },
        ),

        // ✅ ✨ NOUVELLE ROUTE : profil public d’un créateur
        GoRoute(
          path: '/creators/:username',
          name: 'creator_profile',
          builder: (context, state) {
            final username = state.pathParameters['username']!;
            return CreatorProfileScreen(username: username);
          },
        ),
      ],
    );
  }
}
