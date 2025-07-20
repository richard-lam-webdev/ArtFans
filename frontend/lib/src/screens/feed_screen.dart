import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../services/content_service.dart';
import '../providers/theme_provider.dart';
import '../providers/message_provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/snackbar_util.dart';
import '../widgets/bottom_nav.dart';
import '../services/metrics_service.dart';
import '../widgets/feed_card.dart';
import 'search_screen.dart';
import '../providers/auth_provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ContentService _contentService = ContentService();
  List<Map<String, dynamic>> _feed = [];
  bool _loading = true;
  late DateTime _pageLoadStart;

  @override
  void initState() {
    super.initState();
    _pageLoadStart = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loadTime = DateTime.now().difference(_pageLoadStart).inMilliseconds;
      MetricsService.reportPageLoad('feed', loadTime);
    });
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    setState(() => _loading = true);
    try {
      final result = await _contentService.fetchFeed();
      if (!mounted) return;

      context.read<SubscriptionProvider>().initializeFeedSubscriptions(result);

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
    final auth = context.read<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fil d'actualité"),
        actions: [
          IconButton(
            tooltip: 'Recherche',
            icon: const Icon(Icons.search_outlined),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
            },
          ),
          Consumer<MessageProvider>(
            builder: (context, messageProvider, _) {
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
            },
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _feed.isEmpty
              ? const Center(child: Text("Aucun contenu."))
              : RefreshIndicator(
                onRefresh: _fetchFeed,
                child: ListView.builder(
                  itemCount: _feed.length,
                  itemBuilder: (context, index) {
                    final item = _feed[index];
                    return FeedCard(
                      key: ValueKey(item['id']),
                      content: item,
                      onSubscribedChanged: _fetchFeed,
                    );
                  },
                ),
              ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}
