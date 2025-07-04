import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  const BottomNav({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index, bool isAdmin, bool isCreator) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/add-content');
        break;
      case 2:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recherche à venir !')));
        break;
      case 3:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profil à venir !')));
        break;
      case 4:
        if (isCreator) {
          context.go('/my-contents');
        } else if (isAdmin) {
          context.go('/admin');
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
    final isWideScreen = MediaQuery.of(context).size.width > 480;

    final items = <SalomonBottomBarItem>[
      SalomonBottomBarItem(
        icon: const Icon(Icons.home),
        title: isWideScreen ? const Text('Accueil') : const SizedBox.shrink(),
        selectedColor: Colors.deepPurple,
      ),
      SalomonBottomBarItem(
        icon: const Icon(Icons.add_box),
        title: isWideScreen ? const Text('Ajouter') : const SizedBox.shrink(),
        selectedColor: Colors.green[700]!,
      ),
      SalomonBottomBarItem(
        icon: const Icon(Icons.dynamic_feed),
        title: isWideScreen ? const Text('Feed') : const SizedBox.shrink(),
        selectedColor: Colors.indigo[700]!,
      ),
      SalomonBottomBarItem(
        icon: const Icon(Icons.search),
        title: isWideScreen ? const Text('Recherche') : const SizedBox.shrink(),
        selectedColor: Colors.blue[700]!,
      ),
      SalomonBottomBarItem(
        icon: const Icon(Icons.person),
        title: isWideScreen ? const Text('Profil') : const SizedBox.shrink(),
        selectedColor: Colors.teal[700]!,
      ),
    ];

    if (isCreator) {
      items.add(
        SalomonBottomBarItem(
          icon: const Icon(Icons.folder_copy),
          title:
              isWideScreen ? const Text('Contenus') : const SizedBox.shrink(),
          selectedColor: Colors.orange[700]!,
        ),
      );
    } else if (isAdmin) {
      items.add(
        SalomonBottomBarItem(
          icon: const Icon(Icons.admin_panel_settings),
          title: isWideScreen ? const Text('Admin') : const SizedBox.shrink(),
          selectedColor: Colors.red[700]!,
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
