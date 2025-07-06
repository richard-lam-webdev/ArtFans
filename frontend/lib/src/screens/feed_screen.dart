import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/content_service.dart';
import '../providers/theme_provider.dart';
import '../utils/snackbar_util.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/feed_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ContentService _contentService = ContentService();
  List<Map<String, dynamic>> _feed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    setState(() => _loading = true);
    try {
      final result = await _contentService.fetchFeed();
      if (!mounted) return;
      setState(() {
        _feed = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context, "Erreur : $e", type: SnackBarType.error);
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width > 600 ? 2 : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fil d'actualité"),
        actions: [
          Consumer<ThemeProvider>(
            builder:
                (ctx, theme, _) => IconButton(
                  tooltip:
                      theme.isDarkMode ? "Passer en clair" : "Passer en sombre",
                  icon: Icon(
                    theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                  onPressed: () => theme.toggleTheme(!theme.isDarkMode),
                ),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _feed.isEmpty
              ? const Center(child: Text("Aucun contenu."))
              : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.75,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _feed.length,
                itemBuilder: (ctx, index) {
                  final content = _feed[index];
                  return FeedCard(
                    key: ValueKey(content['id']),
                    content: _feed[index],
                    onSubscribedChanged: _fetchFeed,
                  );
                },
              ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}
