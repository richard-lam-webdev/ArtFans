import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/creator_service.dart';
import '../services/content_service.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String username;

  const CreatorProfileScreen({super.key, required this.username});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  final CreatorService _creatorService = CreatorService();
  final ContentService _contentService = ContentService();

  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  bool _subscribing = false;
  bool _isSubscribed = false; // À remplacer par une vraie vérification plus tard

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _creatorService.fetchPublicCreatorProfile(widget.username);
      if (!mounted) return;
      setState(() {
        _profile = data;
        _loading = false;
        // _isSubscribed = false; → à améliorer plus tard avec une vraie vérification d'abonnement
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleSubscription() async {
    setState(() => _subscribing = true);

    try {
      final creatorId = _profile!['id'] as String;

      if (_isSubscribed) {
        await _contentService.unsubscribe(creatorId);
      } else {
        await _contentService.subscribe(creatorId);
      }

      if (!mounted) return;
      setState(() {
        _isSubscribed = !_isSubscribed;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSubscribed
              ? "Abonnement effectué !"
              : "Désabonnement effectué."),
        ),
      );

      // ✅ Recharge les infos du créateur pour mettre à jour le nombre d’abonnés
      await _loadProfile();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => _subscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Erreur : $_error'));

    final p = _profile!;
    final contents = List<Map<String, dynamic>>.from(p['content_preview'] ?? []);
    final createdAt = DateTime.tryParse(p['created_at'] ?? '');
    final formattedDate = createdAt != null
        ? DateFormat.yMMMMd().format(createdAt)
        : 'Date inconnue';

    return Scaffold(
      appBar: AppBar(title: Text('@${p['username']}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (p['avatar_url'] != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(p['avatar_url']),
              ),
            const SizedBox(height: 12),
            Text(
              p['bio'] ?? 'Aucune bio',
              style: const TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text('Inscrit depuis le $formattedDate'),
            const SizedBox(height: 8),
            Text('${p['subscriber_count']} abonnés'),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: Icon(_isSubscribed ? Icons.cancel : Icons.favorite),
              label: Text(_isSubscribed ? 'Se désabonner' : 'S’abonner'),
              onPressed: _subscribing ? null : _toggleSubscription,
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Contenus récents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (contents.isEmpty)
              const Text('Aucun contenu.'),
            for (final content in contents)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(content['title'] ?? 'Sans titre'),
                  subtitle: Text('ID: ${content['id']}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
