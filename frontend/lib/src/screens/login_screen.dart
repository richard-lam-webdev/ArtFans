// lib/src/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:frontend/src/services/metrics_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  late DateTime _pageLoadStart;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
    _pageLoadStart = DateTime.now();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loadTime = DateTime.now().difference(_pageLoadStart).inMilliseconds;
      MetricsService.reportPageLoad('login', loadTime);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    setState(() {
      _isLoading = true;
    });

    await authProvider.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) {
      return;
    }

    if (authProvider.status == AuthStatus.authenticated) {
      // Charger le profil puis rediriger
      await context.read<UserProvider>().fetchUserProfile();
      if (!mounted) return;
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Champ Email
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'email est requis';
                      }
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Format d\'email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Champ Mot de passe
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Minimum 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Loader ou bouton
                  if (_isLoading || authProvider.status == AuthStatus.loading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Se connecter'),
                    ),
                  const SizedBox(height: 12),
                  // Message d’erreur si besoin
                  if (authProvider.status == AuthStatus.error &&
                      authProvider.errorMessage != null)
                    Text(
                      authProvider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 16),
                  // Lien vers Inscription
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Pas de compte ? Inscription'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
