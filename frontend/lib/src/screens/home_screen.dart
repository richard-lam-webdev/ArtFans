import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: () {
          if (userProvider.status == UserStatus.loading ||
              userProvider.status == UserStatus.initial) {
            return const CircularProgressIndicator();
          }

          if (userProvider.status == UserStatus.error) {
            return Text(
              'Erreur : ${userProvider.errorMessage}',
              style: const TextStyle(color: Colors.red),
            );
          }

          final user = userProvider.user!;
          final role = user['Role'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue, ${user['Username']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Email : ${user['Email']}'),
                const SizedBox(height: 8),
                Text('Rôle : $role'),
                const SizedBox(height: 8),
                Text('Inscrit depuis : ${user['CreatedAt']}'),
                const SizedBox(height: 24),

                // ✅ Bouton visible uniquement si creator
                if (role == 'creator')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.folder_copy),
                    label: const Text("Mes contenus"),
                    onPressed: () => context.push('/my-contents'),
                  ),
              ],
            ),
          );
        }(),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}
