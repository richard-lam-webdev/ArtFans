import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Récupère l'utilisateur actuellement connecté
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Affiche la photo de profil si disponible
            if (user?.photoURL != null) ...[
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(user!.photoURL!),
              ),
              const SizedBox(height: 16),
            ],
            // Affiche le nom d'affichage ou l'email
            Text(
              'Bienvenue, ${user?.displayName ?? user?.email} !',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
