import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
        context.go('/profile');
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

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.add_box),
        label: 'Ajouter',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.search),
        label: 'Recherche',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
    ];

    // Ajout conditionnel
    if (isCreator) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.folder_copy),
          label: 'Contenus',
        ),
      );
    } else if (isAdmin) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex < items.length ? currentIndex : 0,
      onTap: (i) => _onTap(context, i, isAdmin, isCreator),
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      items: items,
    );
  }
}
