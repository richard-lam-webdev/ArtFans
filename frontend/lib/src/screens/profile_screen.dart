import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
        title: const Text('Mon Profil'),
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.account_circle, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Bienvenue, ${user['Username']}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text('📧 Email : ${user['Email']}'),
                const SizedBox(height: 8),
                Text('🛡️ Rôle : $role'),
                const SizedBox(height: 8),
                Text('📅 Inscrit depuis : ${user['CreatedAt']}'),
                const SizedBox(height: 32),

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
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }
}
