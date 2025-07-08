// lib/src/screens/edit_content_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  // Charge dynamiquement l’URL de base depuis .env
  final String _baseUrl = (() {
    try {
      return dotenv.env['API_URL'] ?? 'http://localhost:8080';
    } catch (_) {
      return 'http://localhost:8080';
    }
  })();

  String get baseUrl => _baseUrl;

  final ContentService _contentService = ContentService();

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool _loading = true;
  bool _loaded = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final data = await _contentService.getContentById(widget.contentId);
      if (!mounted) return;
      setState(() {
        _titleCtrl.text = data?['title'] ?? '';
        _bodyCtrl.text = data?['body'] ?? '';
        _priceCtrl.text = (data?['price'] ?? '').toString();
        _filePath = data?['file_path'];
        _loading = false;
        _loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
        context,
        "Erreur chargement : $e",
        type: SnackBarType.error,
      );
      setState(() {
        _loading = false;
        _loaded = true;
      });
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
      if (!mounted) return;
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
                tooltip: themeProvider.isDarkMode
                    ? "Passer en clair"
                    : "Passer en sombre",
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                onPressed: () =>
                    themeProvider.toggleTheme(!themeProvider.isDarkMode),
              );
            },
          ),
        ],
      ),
      body: _loading || !_loaded
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
                            if (_filePath != null && _filePath!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    '$baseUrl/uploads/$_filePath',
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Text(
                                      "Image introuvable",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ),
                            TextFormField(
                              controller: _titleCtrl,
                              decoration:
                                  const InputDecoration(labelText: "Titre"),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? "Requis" : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bodyCtrl,
                              decoration: const InputDecoration(
                                  labelText: "Description"),
                              maxLines: 5,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? "Requis" : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _priceCtrl,
                              decoration:
                                  const InputDecoration(labelText: "Prix"),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Requis";
                                return int.tryParse(v) == null
                                    ? "Nombre invalide"
                                    : null;
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
