import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../services/content_service.dart';
import '../providers/theme_provider.dart';
import '../providers/message_provider.dart';
import '../utils/snackbar_util.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/protected_image.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fil d'actualité"),
        actions: [
          // Bouton Messages avec badge
          Consumer<MessageProvider>(
            builder: (context, messageProvider, child) {
              final unreadCount = messageProvider.totalUnreadCount;
              
              return IconButton(
                tooltip: "Messages",
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.message_outlined),
                    if (unreadCount > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  context.push('/messages');
                },
              );
            },
          ),
          // Bouton Theme
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _feed.isEmpty
              ? const Center(child: Text("Aucun contenu."))
              : ListView.builder(
                  itemCount: _feed.length,
                  itemBuilder: (context, index) {
                    final item = _feed[index];
                    final contentId = item['id'];
                    final creatorId = item['creator_id'];
                    bool isSubscribed = item['is_subscribed'] ?? false;

                    return StatefulBuilder(
                      builder: (BuildContext innerContext, StateSetter setInner) {
                        return Card(
                          margin: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProtectedImage(
                                contentId: contentId,
                                isSubscribed: item['is_subscribed'] as bool,
                                key: ValueKey(
                                  '$contentId-${item['is_subscribed']}',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item['creator_name'] ?? 'Créateur',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.send, size: 20),
                                          onPressed: () {
                                            context.push(
                                              '/chat/$creatorId',
                                              extra: item['creator_name'] ?? 'Créateur',
                                            );
                                          },
                                          tooltip: 'Envoyer un message',
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['title'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(item['body'] ?? ''),
                                    const SizedBox(height: 6),
                                    if (!isSubscribed)
                                      const Text(
                                        "🔒 Abonne-toi pour voir sans watermark",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(
                                          innerContext,
                                        );
                                        try {
                                          if (isSubscribed) {
                                            await _contentService.unsubscribe(
                                              creatorId,
                                            );
                                          } else {
                                            await _contentService.subscribe(
                                              creatorId,
                                            );
                                          }
                                          if (!mounted) return;
                                          setState(() {
                                            item['is_subscribed'] = !isSubscribed;
                                          });
                                        } catch (e) {
                                          if (!innerContext.mounted) return;
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text("Erreur : $e"),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(
                                        isSubscribed
                                            ? 'Se désabonner'
                                            : 'S\'abonner',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}