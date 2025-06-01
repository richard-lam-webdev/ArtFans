import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/sign_in_page.dart';
import 'pages/home_page.dart'; // À créer ensuite pour la page d’accueil

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArtFans',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
    );
  }
}

/// Widget qui redirige selon l’état d’authentification
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        // Tant que la connexion Firebase n’est pas établie, on peut afficher un loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Si l’utilisateur est connecté, on affiche la HomePage
        if (snapshot.hasData) {
          return const HomePage();
        }
        // Sinon on affiche la page de connexion
        return const SignInPage();
      },
    );
  }
}
