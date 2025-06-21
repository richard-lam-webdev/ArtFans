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
              },
            ),
          ],
        ),
        body: TabBarView(children: [const _UsersTab(), const _ContentsTab()]),
        bottomNavigationBar: const BottomNav(currentIndex: 4),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();

    if (prov.status == AdminStatus.loading) {
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
              final isSub = role == 'subscriber';

              return DataRow(
                cells: [
                  DataCell(Text(u['Username'] as String)),
                  DataCell(Text(u['Email'] as String)),
                  DataCell(Text(role)),
                  DataCell(Text(createdAt)),
                  DataCell(
                    // si subscriber → bouton « Promouvoir »
                    isSub
                        ? ElevatedButton(
                          onPressed: () async {
                            try {
                              await context.read<AdminProvider>().updateRole(
                                id,
                                'creator',
                              );
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
                        // sinon (creator ou admin) → bouton « Rétrograder »
                        : ElevatedButton(
                          onPressed: () async {
                            try {
                              await context.read<AdminProvider>().updateRole(
                                id,
                                'subscriber',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rétrogradé en subscriber !'),
                                ),
                              );
                            } catch (e) {
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

class _ContentsTab extends StatelessWidget {
  const _ContentsTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminContentProvider>();

    if (prov.status == AdminContentStatus.initial ||
        prov.status == AdminContentStatus.loading) {
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
          DataColumn(label: Text('Action')),
        ],
        rows:
            contents.map((c) {
              final id = c['ID'] as String? ?? '';
              return DataRow(
                cells: [
                  DataCell(Text(c['Title'] as String? ?? '')),
                  DataCell(Text(c['AuthorID'] as String? ?? '')),
                  DataCell(Text(c['CreatedAt'] as String? ?? '')),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () async {
                        await prov.deleteContent(id);
                        // Tu peux aussi afficher un SnackBar si tu veux :
                        final msg =
                            prov.status == AdminContentStatus.error
                                ? prov.errorMessage
                                : 'Contenu supprimé !';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(msg ?? '')));
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}
