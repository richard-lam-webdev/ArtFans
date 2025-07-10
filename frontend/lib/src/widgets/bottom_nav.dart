import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/feature_flag_provider.dart';
import '../constants/features.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  const BottomNav({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index, bool isAdmin, bool isCreator) {
    final chatEnabled = context.read<FeatureFlagProvider>().features.any(
      (f) => f.key == featureChat && f.enabled,
    );

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/add-content');
        break;
      case 2:
        context.go('/my-subscriptions');
        break;
      case 3:
        context.go('/profile');
        break;
      case 4:
        if (chatEnabled) {
          context.go('/messages');
        } else if (isCreator) {
          context.go('/my-contents');
        } else if (isAdmin) {
          context.go('/admin');
        }
        break;
      case 5:
        if (chatEnabled) {
          if (isCreator) {
            context.go('/my-contents');
          } else if (isAdmin) {
            context.go('/admin');
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = context.watch<UserProvider>().user;
    final isAdmin =
        auth.status == AuthStatus.authenticated && user?['Role'] == 'admin';
    final isCreator =
        auth.status == AuthStatus.authenticated && user?['Role'] == 'creator';
    final isWide = MediaQuery.of(context).size.width > 480;

    // Items de base
    final items = <SalomonBottomBarItem>[
      SalomonBottomBarItem(
        icon: const Icon(Icons.home),
        title: isWide ? const Text('Accueil') : const SizedBox.shrink(),
        selectedColor: Colors.deepPurple,
      ),
      SalomonBottomBarItem(
        icon: const Icon(Icons.add_box),
        title: isWide ? const Text('Ajouter') : const SizedBox.shrink(),
        selectedColor: Colors.green,
      ),
      SalomonBottomBarItem(
        icon: const Icon(Icons.dynamic_feed),
        title: isWide ? const Text('Abonnements') : const SizedBox.shrink(),
        selectedColor: Colors.indigo,
      ),
      SalomonBottomBarItem(
        icon: const Icon(Icons.person),
        title: isWide ? const Text('Profil') : const SizedBox.shrink(),
        selectedColor: Colors.teal,
      ),
    ];

    // Contenu créateur ou Admin
    if (isCreator) {
      items.add(
        SalomonBottomBarItem(
          icon: const Icon(Icons.folder_copy),
          title: isWide ? const Text('Contenus') : const SizedBox.shrink(),
          selectedColor: Colors.orange,
        ),
      );
    } else if (isAdmin) {
      items.add(
        SalomonBottomBarItem(
          icon: const Icon(Icons.admin_panel_settings),
          title: isWide ? const Text('Admin') : const SizedBox.shrink(),
          selectedColor: Colors.red,
        ),
      );
    }

    return SalomonBottomBar(
      currentIndex: currentIndex < items.length ? currentIndex : 0,
      onTap: (i) => _onTap(context, i, isAdmin, isCreator),
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      items: items,
      backgroundColor: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuint,
    );
  }
}
