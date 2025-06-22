// lib/src/screens/admin_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/admin_content_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
      context.read<AdminContentProvider>().fetchContents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Back-office Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Utilisateurs', icon: Icon(Icons.person)),
              Tab(text: 'Contenus', icon: Icon(Icons.article)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                auth.logout();
                // GoRouter redirigera vers /login
              },
            ),
          ],
        ),
        body: const TabBarView(children: [_UsersTab(), _ContentsTab()]),
        bottomNavigationBar: const BottomNav(currentIndex: 4),
      ),
    );
  }
}

// ----------------------------
// Onglet Utilisateurs
// ----------------------------
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();

    if (prov.status == AdminStatus.loading ||
        prov.status == AdminStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.status == AdminStatus.error) {
      return Center(
        child: Text(
          'Erreur : ${prov.errorMessage}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final users = prov.users;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
              final id = u['ID'] as String;
              final role = u['Role'] as String;
              final createdAt = u['CreatedAt'] as String;
              final isSubscriber = role == 'subscriber';

              return DataRow(
                cells: [
                  DataCell(Text(u['Username'] as String)),
                  DataCell(Text(u['Email'] as String)),
                  DataCell(Text(role)),
                  DataCell(Text(createdAt)),
                  DataCell(
                    isSubscriber
                        // Si subscriber → bouton Promouvoir
                        ? ElevatedButton(
                          onPressed: () async {
                            try {
                              await context.read<AdminProvider>().updateRole(
                                id,
                                'creator',
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Promu en creator !'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur : $e')),
                              );
                            }
                          },
                          child: const Text('Promouvoir'),
                        )
                        // Sinon (creator/admin) → bouton Rétrograder
                        : ElevatedButton(
                          onPressed: () async {
                            try {
                              await context.read<AdminProvider>().updateRole(
                                id,
                                'subscriber',
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rétrogradé en subscriber !'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur : $e')),
                              );
                            }
                          },
                          child: const Text('Rétrograder'),
                        ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}

// ----------------------------
// Onglet Contenus
// ----------------------------
class _ContentsTab extends StatelessWidget {
  const _ContentsTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminContentProvider>();

    if (prov.status == AdminContentStatus.loading ||
        prov.status == AdminContentStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.status == AdminContentStatus.error) {
      return Center(
        child: Text(
          'Erreur : ${prov.errorMessage}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final contents = prov.contents;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Titre')),
          DataColumn(label: Text('Auteur')),
          DataColumn(label: Text('Publié le')),
          DataColumn(label: Text('Statut')),
          DataColumn(label: Text('Actions')),
        ],
        rows:
            contents.map((c) {
              final id = c['ID'] as String? ?? '';
              final title = c['Title'] as String? ?? '';
              final author = c['AuthorID'] as String? ?? '';
              final createdAt = c['CreatedAt'] as String? ?? '';
              final status = c['Status'] as String? ?? 'pending';

              Widget actionCell;
              if (status == 'pending') {
                actionCell = Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Approuver',
                      onPressed: () => prov.approveContent(id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Rejeter',
                      onPressed: () => prov.rejectContent(id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: 'Supprimer',
                      onPressed: () => prov.deleteContent(id),
                    ),
                  ],
                );
              } else {
                final approved = status == 'approved';
                actionCell = Text(
                  approved ? '✅ Approuvé' : '🚫 Rejeté',
                  style: TextStyle(
                    color: approved ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }

              return DataRow(
                cells: [
                  DataCell(Text(title)),
                  DataCell(Text(author)),
                  DataCell(Text(createdAt)),
                  DataCell(Text(status)),
                  DataCell(actionCell),
                ],
              );
            }).toList(),
      ),
    );
  }
}
