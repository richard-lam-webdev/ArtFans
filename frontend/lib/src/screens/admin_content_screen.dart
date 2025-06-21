// lib/src/screens/admin_content_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_content_provider.dart';
import '../widgets/bottom_nav.dart';
import '../providers/auth_provider.dart';

class AdminContentsScreen extends StatefulWidget {
  const AdminContentsScreen({super.key});

  @override
  State<AdminContentsScreen> createState() => _AdminContentsScreenState();
}

class _AdminContentsScreenState extends State<AdminContentsScreen> {
  @override
  void initState() {
    super.initState();
    // Charge la liste des contenus dès que possible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminContentProvider>().fetchContents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final adminProv = context.watch<AdminContentProvider>();

    Widget body;
    switch (adminProv.status) {
      case AdminContentStatus.loading:
      case AdminContentStatus.initial:
        body = const Center(child: CircularProgressIndicator());
        break;
      case AdminContentStatus.error:
        body = Center(
          child: Text(
            'Erreur : ${adminProv.errorMessage}',
            style: const TextStyle(color: Colors.red),
          ),
        );
        break;
      case AdminContentStatus.loaded:
        final contents = adminProv.contents;
        body = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Titre')),
              DataColumn(label: Text('AuteurID')),
              DataColumn(label: Text('Créé le')),
              DataColumn(label: Text('Action')),
            ],
            rows:
                contents.map((c) {
                  final id = c['ID'] as String;
                  final title = c['Title'] as String? ?? '';
                  final author = c['AuthorID'] as String? ?? '';
                  final createdAt = c['CreatedAt'] as String? ?? '';
                  return DataRow(
                    cells: [
                      DataCell(Text(title)),
                      DataCell(Text(author)),
                      DataCell(Text(createdAt)),
                      DataCell(
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            await context
                                .read<AdminContentProvider>()
                                .deleteContent(id);
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Back-office Contenus'),
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
      body: Padding(padding: const EdgeInsets.all(16.0), child: body),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }
}
