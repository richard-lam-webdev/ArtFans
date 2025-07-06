// lib/widgets/feed_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/content_service.dart';
import 'protected_image.dart';
import 'comments_sheet.dart';

class FeedCard extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onSubscribedChanged;

  const FeedCard({
    super.key,
    required this.content,
    required this.onSubscribedChanged,
  });

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  final _svc = ContentService();

  Future<void> _toggleSubscribe() async {
    final currently = widget.content['is_subscribed'] as bool;
    try {
      if (currently) {
        await _svc.unsubscribe(widget.content['creator_id'] as String);
      } else {
        await _svc.subscribe(widget.content['creator_id'] as String);
      }
      setState(() {
        widget.content['is_subscribed'] = !currently;
      });
      widget.onSubscribedChanged();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur abonnement : $e')));
    }
  }

  Future<void> _toggleLike() async {
    final currentlyLiked = widget.content['liked_by_user'] as bool? ?? false;
    final currentCount = widget.content['likes_count'] as int? ?? 0;
    final newLiked = !currentlyLiked;
    final newCount = currentCount + (newLiked ? 1 : -1);

    // 1) mise à jour optimiste
    setState(() {
      widget.content['liked_by_user'] = newLiked;
      widget.content['likes_count'] = newCount;
    });

    // 2) appel réseau
    try {
      if (newLiked) {
        await _svc.likeContent(widget.content['id'] as String);
      } else {
        await _svc.unlikeContent(widget.content['id'] as String);
      }
    } catch (e) {
      // 3) rollback
      setState(() {
        widget.content['liked_by_user'] = currentlyLiked;
        widget.content['likes_count'] = currentCount;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur like : $e')));
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => FractionallySizedBox(
            heightFactor: 0.4,
            child: CommentsSheet(contentId: widget.content['id'] as String),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubscribed = widget.content['is_subscribed'] as bool? ?? false;
    final liked = widget.content['liked_by_user'] as bool? ?? false;
    final likeCount = widget.content['likes_count'] as int? ?? 0;
    final creatorId = widget.content['creator_id'] as String;
    final creatorName = widget.content['creator_name'] as String? ?? 'Créateur';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entête : avatar / nom / icône message / bouton s'abonner
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                widget.content['creator_avatar_url'] ??
                    'https://placehold.co/40x40',
              ),
            ),
            title: Text(creatorName),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.send, size: 20),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Envoyer un message',
                  onPressed: () {
                    GoRouter.of(
                      context,
                    ).push('/chat/$creatorId', extra: creatorName);
                  },
                ),
                TextButton(
                  onPressed: _toggleSubscribe,
                  child: Text(isSubscribed ? 'Se désabonner' : 'S’abonner'),
                ),
              ],
            ),
          ),

          // Image protégée
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ProtectedImage(
              contentId: widget.content['id'] as String,
              isSubscribed: isSubscribed,
              key: ValueKey('${widget.content['id']}-$isSubscribed'),
            ),
          ),

          // Actions sociale : like + commentaire
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.red : null,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$likeCount'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: _openComments,
                ),
                const Spacer(),
              ],
            ),
          ),

          // Titre + corps
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              widget.content['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              widget.content['body'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
