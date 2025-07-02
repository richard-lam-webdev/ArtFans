import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../widgets/bottom_nav.dart';
import '../utils/snackbar_util.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AddContentScreen extends StatefulWidget {
  const AddContentScreen({super.key});

  @override
  State<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends State<AddContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  PlatformFile? _selectedFile;
  Uint8List? _selectedFileBytes;
  String? _error;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    setState(() => _error = null);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      _selectedFile = result.files.first;
      _selectedFileBytes = result.files.first.bytes;
    } else {
      _selectedFile = null;
      _selectedFileBytes = null;
    }
    setState(() {});
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedFile == null) {
      setState(() => _error = 'Tous les champs sont requis.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService().getToken();
      final username = await AuthService().getUsername();
      const role = 'creator';

      if (token == null || username == null) {
        setState(() => _error = 'Session expirée ; reconnecte-toi.');
        return;
      }

      final String baseUrl = (() {
        try {
          return dotenv.env['API_URL'] ?? 'http://localhost:8080';
        } catch (_) {
          return 'http://localhost:8080';
        }
      })();

      final uri = Uri.parse('$baseUrl/api/contents');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['username'] = username
        ..fields['role'] = role
        ..fields['title'] = _titleCtrl.text.trim()
        ..fields['body'] = _bodyCtrl.text.trim()
        ..fields['price'] = _priceCtrl.text.trim();

      final fileName = _selectedFile?.name ?? 'file';
      if (UniversalPlatform.isWeb || _selectedFile?.path == null) {
        if (_selectedFileBytes == null) {
          setState(() => _error = 'Impossible de lire le fichier.');
          return;
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _selectedFileBytes!,
            filename: fileName,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            _selectedFile!.path!,
            filename: fileName,
          ),
        );
      }

      final streamed = await request.send();

      if (!mounted) return;

      if (streamed.statusCode == 201) {
        if (!mounted) return;
        context.go('/home');
      } else {
        final respBody = await streamed.stream.bytesToString();
        if (!mounted) return;
        setState(() => _error = 'Erreur streamed.statusCode : $respBody');
        showCustomSnackBar(context, _error!, type: SnackBarType.error);
      }
    } catch (e) {
      setState(() => _error = e.toString());
      showCustomSnackBar(context, "Erreur : $e", type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    final fileName = _selectedFile?.name ?? 'Choisir une image';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publier un contenu'),
        centerTitle: true,
      ),
      body: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Titre
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Titre',
                          prefixIcon: Icon(Icons.title_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Titre requis' : null,
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _bodyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description_outlined),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (v) => (v == null || v.isEmpty) ? 'Description requise' : null,
                      ),
                      const SizedBox(height: 16),
                      // Prix
                      TextFormField(
                        controller: _priceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Prix (€)',
                          prefixIcon: Icon(Icons.euro_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Prix requis' : null,
                      ),
                      const SizedBox(height: 18),
                      // Sélecteur de fichier & preview
                      GestureDetector(
                        onTap: _isLoading ? null : _pickFile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withAlpha((0.07 * 255).round()), // Correction deprecation
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.dividerColor.withAlpha((0.6 * 255).round()), // Correction deprecation
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(Icons.image_outlined, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  fileName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_selectedFileBytes != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _selectedFileBytes!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (_selectedFileBytes == null)
                                const Icon(Icons.add_photo_alternate, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Message d'erreur stylisé
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      // Bouton Publier
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Publier'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(fontSize: 17),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}
