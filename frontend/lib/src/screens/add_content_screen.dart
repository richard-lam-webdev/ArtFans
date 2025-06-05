import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

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
  Uint8List? _selectedFileBytes; // Pour web
  String? _error;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    setState(() => _error = null);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf'],
      withData: true, // Nécessaire pour web !
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
        _selectedFileBytes = result.files.first.bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      setState(() => _error = "Tous les champs sont requis.");
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      var uri = Uri.parse(
        'http://localhost:8080/api/contents',
      ); // Change l'URL si besoin
      var request =
          http.MultipartRequest('POST', uri)
            ..fields['title'] = _titleCtrl.text.trim()
            ..fields['body'] = _bodyCtrl.text.trim()
            ..fields['price'] = _priceCtrl.text.trim();

      // --- Gestion du fichier ---
      if (UniversalPlatform.isWeb) {
        // Pour le web, utiliser bytes
        if (_selectedFileBytes == null) throw Exception("Fichier corrompu.");
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _selectedFileBytes!,
            filename: _selectedFile!.name,
          ),
        );
      } else {
        // Mobile/Desktop : utiliser le chemin
        if (_selectedFile!.path == null) throw Exception("Fichier invalide.");
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            _selectedFile!.path!,
            filename: _selectedFile!.name,
          ),
        );
      }

      var response = await request.send();

      if (response.statusCode == 201) {
        if (!mounted) return;
        Navigator.of(context).pop(); // ou affiche un message de succès
      } else {
        final respStr = await response.stream.bytesToString();
        setState(() => _error = "Erreur : $respStr");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
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
      appBar: AppBar(title: const Text('Ajouter du contenu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator:
                    (v) => (v == null || v.isEmpty) ? 'Titre requis' : null,
              ),
              TextFormField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator:
                    (v) =>
                        (v == null || v.isEmpty) ? 'Description requise' : null,
              ),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Prix (€)'),
                keyboardType: TextInputType.number,
                validator:
                    (v) => (v == null || v.isEmpty) ? 'Prix requis' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _selectedFile == null
                      ? "Choisir un fichier"
                      : _selectedFile!.name,
                ),
                onPressed: _isLoading ? null : _pickFile,
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Publier"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
