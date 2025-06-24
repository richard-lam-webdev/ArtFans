import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/content_service.dart';
import '../utils/snackbar_util.dart';
import '../providers/theme_provider.dart';

class EditContentScreen extends StatefulWidget {
  final String contentId;

  const EditContentScreen({super.key, required this.contentId});

  @override
  State<EditContentScreen> createState() => _EditContentScreenState();
}

class _EditContentScreenState extends State<EditContentScreen> {
  final ContentService _contentService = ContentService();

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool _loading = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final data = await _contentService.getContentById(widget.contentId);
      if (data != null) {
        _titleCtrl.text = data['title'] ?? '';
        _bodyCtrl.text = data['body'] ?? '';
        _priceCtrl.text = (data['price'] ?? '').toString();
      }
    } catch (e) {
      showCustomSnackBar(
        context,
        "Erreur chargement : $e",
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loaded = true;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _contentService.updateContent(
        widget.contentId,
        _titleCtrl.text.trim(),
        _bodyCtrl.text.trim(),
        int.parse(_priceCtrl.text.trim()),
      );
      if (!mounted) return;
      showCustomSnackBar(
        context,
        "Contenu mis à jour.",
        type: SnackBarType.success,
      );
      context.go('/my-contents');
    } catch (e) {
      showCustomSnackBar(context, "Erreur : $e", type: SnackBarType.error);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Éditer le contenu"),
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
          _loading || !_loaded
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 600 : double.infinity,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              TextFormField(
                                controller: _titleCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Titre",
                                ),
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? "Requis"
                                            : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _bodyCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Description",
                                ),
                                maxLines: 5,
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? "Requis"
                                            : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _priceCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Prix",
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return "Requis";
                                  if (int.tryParse(v) == null)
                                    return "Nombre invalide";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _submit,
                                child: const Text("Enregistrer"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
