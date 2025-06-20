// lib/src/screens/admin_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/bottom_nav.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Charge la liste des utilisateurs dès que possible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final adminProv = context.watch<AdminProvider>();

    Widget content;
    switch (adminProv.status) {
      case AdminStatus.loading:
        content = const Center(child: CircularProgressIndicator());
        break;
      case AdminStatus.error:
        content = Center(
          child: Text(
            'Erreur : ${adminProv.errorMessage}',
            style: const TextStyle(color: Colors.red),
          ),
        );
        break;
      case AdminStatus.loaded:
        final users = adminProv.users;
        content = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Utilisateur')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Rôle')),
              DataColumn(label: Text('Inscrit le')),
              DataColumn(label: Text('Action')),
            ],
            rows:
                users.map((u) {
                  final id = u['ID'] as String? ?? '';
                  final role = u['Role'] as String? ?? '';
                  final createdAt = u['CreatedAt'] as String? ?? '';

                  return DataRow(
                    cells: [
                      DataCell(Text(u['Username'] as String? ?? '')),
                      DataCell(Text(u['Email'] as String? ?? '')),
                      DataCell(Text(role)),
                      DataCell(Text(createdAt)),
                      DataCell(
                        role == 'subscriber'
                            // bouton Promouvoir pour les subscribers
                            ? ElevatedButton(
                              onPressed: () async {
                                try {
                                  await context
                                      .read<AdminProvider>()
                                      .updateRole(id, 'creator');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Promu en creator !'),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erreur : $e')),
                                  );
                                }
                              },
                              child: const Text('Promouvoir'),
                            )
                            : role == 'creator'
                            // bouton Rétrograder pour les creators
                            ? ElevatedButton(
                              onPressed: () async {
                                try {
                                  await context
                                      .read<AdminProvider>()
                                      .updateRole(id, 'subscriber');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Rétrogradé en subscriber !',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erreur : $e')),
                                  );
                                }
                              },
                              child: const Text('Rétrograder'),
                            )
                            // pour un admin (ou autres rôles éventuels)
                            : const Text('-'),
                      ),
                    ],
                  );
                }).toList(),
          ),
        );
        break;
      default:
        content = const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Back-office Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProv.logout();
              // GoRouter redirigera vers /login automatiquement
            },
          ),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: content),
      bottomNavigationBar: const BottomNav(currentIndex: 4),
    );
  }
}
