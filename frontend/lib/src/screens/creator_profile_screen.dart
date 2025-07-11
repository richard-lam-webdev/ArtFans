import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CreatorProfileScreen extends StatefulWidget {
  final String username;

  const CreatorProfileScreen({super.key, required this.username});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  Map<String, dynamic>? _creator;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCreatorProfile();
  }

  Future<void> _fetchCreatorProfile() async {
    final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';
    final url = Uri.parse('$baseUrl/api/creators/${widget.username}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _creator = data;
          _isLoading = false;
        });
      } else {
        final errorBody = jsonDecode(response.body);
        setState(() {
          _error = errorBody['error'] ?? 'Erreur inconnue';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Erreur réseau : $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final creator = _creator;

    return Scaffold(
      appBar: AppBar(
        title: Text("Profil de ${widget.username}"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : creator == null
                  ? const Center(child: Text('Créateur introuvable.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(
                              creator['avatar_url'] ??
                                  'https://placehold.co/100x100',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            creator['username'] ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            creator['bio'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${creator['subscriber_count'] ?? 0} abonnés',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),

                          const Divider(),

                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Aperçu des contenus',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          ...List.generate((creator['content_preview'] as List).length, (i) {
                            final content = creator['content_preview'][i];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      content['title'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      content['body'] ?? '',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
    );
  }
}
