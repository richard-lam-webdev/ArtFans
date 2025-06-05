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
      withData: true, // Pour web
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
      setState(() => _error = "Tous les champs sont requis et un fichier doit être sélectionné.");
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      var uri = Uri.parse('http://localhost:8080/api/contents');
      var request = http.MultipartRequest('POST', uri)
        ..fields['title'] = _titleCtrl.text.trim()
        ..fields['body'] = _bodyCtrl.text.trim()
        ..fields['price'] = _priceCtrl.text.trim();

      // --- Gestion du fichier ---
      if (UniversalPlatform.isWeb) {
        if (_selectedFileBytes == null) throw Exception("Fichier corrompu.");
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _selectedFileBytes!,
            filename: _selectedFile!.name,
          ),
        );
      } else {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contenu ajouté !")),
        );
        Navigator.of(context).pop(); // Retour après succès
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
    final maxWidth = MediaQuery.of(context).size.width > 600 ? 400.0 : MediaQuery.of(context).size.width * 0.9;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajout de tamere')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'caca',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Titre requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bodyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (v) => (v == null || v.isEmpty) ? 'Description requise' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Prix (€)',
                          prefixIcon: Icon(Icons.euro),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Prix requis' : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: Text(_selectedFile == null ? "Choisir un fichier" : _selectedFile!.name),
                        onPressed: _isLoading ? null : _pickFile,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Publier"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
