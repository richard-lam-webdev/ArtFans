import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/content_service.dart';
import '../utils/snackbar_util.dart';
import '../providers/theme_provider.dart';

class MyContentsScreen extends StatefulWidget {
  const MyContentsScreen({super.key});

  @override
  State<MyContentsScreen> createState() => _MyContentsScreenState();
}

class _MyContentsScreenState extends State<MyContentsScreen> {
  final ContentService _contentService = ContentService();
  List<Map<String, dynamic>> _contents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchContents();
  }

  Future<void> _fetchContents() async {
    setState(() => _loading = true);
    try {
      final all = await _contentService.fetchMyContents();
      setState(() {
        _contents = all;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      showCustomSnackBar(context, "Erreur : $e", type: SnackBarType.error);
    }
  }

  Future<void> _confirmAndDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Confirmation"),
            content: const Text("Supprimer ce contenu ?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Annuler"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Supprimer"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _contentService.deleteContent(id);
        setState(() {
          _contents.removeWhere((c) => c['id'] == id);
        });
        showCustomSnackBar(
          context,
          "Contenu supprimé.",
          type: SnackBarType.success,
        );
      } catch (e) {
        showCustomSnackBar(context, "Erreur : $e", type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes contenus"),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                tooltip:
                    themeProvider.isDarkMode
                        ? "Passer en clair"
                        : "Passer en sombre",
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                onPressed: () {
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
              );
            },
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _contents.isEmpty
              ? const Center(child: Text("Aucun contenu."))
              : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contents.length,
                    itemBuilder: (context, index) {
                      final content = _contents[index];
                      final date = DateTime.tryParse(
                        content['created_at'] ?? '',
                      );
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isWide ? 700 : double.infinity,
                          ),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(content['title'] ?? 'Sans titre'),
                              subtitle: Text(
                                "Statut : ${content['status']} • ${date != null ? DateFormat.yMd().format(date) : ''}",
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      context.push(
                                        "/edit-content/${content['id']}",
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed:
                                        () => _confirmAndDelete(content['id']),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
