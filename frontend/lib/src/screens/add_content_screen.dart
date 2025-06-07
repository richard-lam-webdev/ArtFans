import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';   

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
      _selectedFile      = result.files.first;
      _selectedFileBytes = result.files.first.bytes;
    } else {
      _selectedFile      = null;
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
      _error     = null;
    });

    try {
      final token    = await AuthService().getToken();
      final username = await AuthService().getUsername();
      const role     = 'creator';

      if (token == null || username == null) {
        setState(() => _error = 'Session expirée ; reconnecte-toi.');
        return;
      }

      final uri     = Uri.parse('http://localhost:8080/api/contents');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['username']       = username
        ..fields['role']           = role
        ..fields['title']          = _titleCtrl.text.trim()
        ..fields['body']           = _bodyCtrl.text.trim()
        ..fields['price']          = _priceCtrl.text.trim();

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
        Navigator.of(context).pop();
      } else {
        final respBody = await streamed.stream.bytesToString();
        setState(() => _error = 'Erreur ${streamed.statusCode} : $respBody');
      }
    } catch (e) {
      setState(() => _error = e.toString());
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
    final fileName = _selectedFile?.name ?? 'Choisir un fichier';

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
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Titre requis' : null,
              ),
              TextFormField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Description requise' : null,
              ),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Prix (€)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Prix requis' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: Text(fileName),
                onPressed: _isLoading ? null : _pickFile,
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Publier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
