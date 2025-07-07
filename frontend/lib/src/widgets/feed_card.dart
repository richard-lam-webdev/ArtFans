// lib/widgets/feed_card.dart
import 'package:flutter/material.dart';
import '../services/content_service.dart';
import 'protected_image.dart';
import 'comments_sheet.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/snackbar_util.dart';

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
  late bool isSubscribed;
  final _svc = ContentService();
  bool _isLoadingSubscription = false;

  @override
  void initState() {
    super.initState();
    isSubscribed = widget.content['is_subscribed'] as bool;
  }
  Future<void> _toggleSubscribe() async {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final creatorId = widget.content['creator_id']?.toString();
    final creatorName = widget.content['creator_name']?.toString() ?? 'ce créateur';
    
    if (creatorId == null) return;

    setState(() => _isLoadingSubscription = true);

    try {
      if (isSubscribed) {
        // Se désabonner avec confirmation
        final confirmed = await _showUnsubscribeDialog(creatorName);
        if (!confirmed) {
          setState(() => _isLoadingSubscription = false);
          return;
        }
        
        final success = await subscriptionProvider.unsubscribeFromCreator(creatorId);
        if (success) {
          setState(() => isSubscribed = false);
          if (mounted) {
            showCustomSnackBar(
              context,
              'Vous êtes désabonné de $creatorName',
              type: SnackBarType.success,
            );
            widget.onSubscribedChanged();
          }
        } else {
          if (mounted) {
            showCustomSnackBar(
              context,
              subscriptionProvider.errorMessage ?? 'Erreur lors du désabonnement',
              type: SnackBarType.error,
            );
          }
        }
      } else {
        // S'abonner avec confirmation (30€)
        final confirmed = await _showSubscribeDialog(creatorName);
        if (!confirmed) {
          setState(() => _isLoadingSubscription = false);
          return;
        }
        
        final success = await subscriptionProvider.subscribeToCreator(creatorId);
        if (success) {
          setState(() => isSubscribed = true);
          if (mounted) {
            showCustomSnackBar(
              context,
              'Abonnement à $creatorName réussi ! (30€)',
              type: SnackBarType.success,
            );
            widget.onSubscribedChanged();
          }
        } else {
          if (mounted) {
            showCustomSnackBar(
              context,
              subscriptionProvider.errorMessage ?? 'Erreur lors de l\'abonnement',
              type: SnackBarType.error,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Erreur : $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSubscription = false);
      }
    }
  }

  Future<bool> _showSubscribeDialog(String creatorName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('S\'abonner à $creatorName'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vous allez vous abonner pour :'),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.euro, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('30€ par mois', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('Durée : 30 jours'),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text('Accès à tout le contenu'),
              ],
            ),
            SizedBox(height: 16),
            Text('Confirmez-vous votre abonnement ?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer (30€)'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _showUnsubscribeDialog(String creatorName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Se désabonner de $creatorName'),
        content: const Text(
          'Êtes-vous sûr de vouloir vous désabonner ?\n\n'
          'Vous perdrez l\'accès au contenu premium de ce créateur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Se désabonner'),
          ),
        ],
      ),
    ) ?? false;
  }


  Future<void> _toggleLike() async {
    // récupère les valeurs courantes
    final bool currentlyLiked =
        widget.content['liked_by_user'] as bool? ?? false;
    final int currentCount = widget.content['likes_count'] as int? ?? 0;

    // prépare les nouvelles valeurs
    final bool newLiked = !currentlyLiked;
    final int newCount = currentlyLiked ? currentCount - 1 : currentCount + 1;

    // mise à jour optimiste
    setState(() {
      widget.content['liked_by_user'] = newLiked;
      widget.content['likes_count'] = newCount;
    });

    // appel réseau
    try {
      if (newLiked) {
        await _svc.likeContent(widget.content['id'] as String);
      } else {
        await _svc.unlikeContent(widget.content['id'] as String);
      }
    } catch (e) {
      if (!mounted) return;
      // rollback
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
    // on lit à chaque build, depuis la map partagée
    final bool liked = widget.content['liked_by_user'] as bool? ?? false;
    final int likeCount = widget.content['likes_count'] as int? ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // entête créateur + abonnement
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                widget.content['creator_avatar_url'] ??
                    'https://placehold.co/40x40',
              ),
            ),
            title: Text(widget.content['creator_name'] ?? 'Créateur'),
            trailing: TextButton(
              onPressed: _isLoadingSubscription ? null : _toggleSubscribe,
              child: _isLoadingSubscription
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isSubscribed ? 'Se désabonner' : 'S\'abonner'),
            ),
          ),

          // image protégée
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ProtectedImage(
              contentId: widget.content['id'] as String,
              isSubscribed: isSubscribed,
              key: ValueKey('${widget.content['id']}-$isSubscribed'),
            ),
          ),

          // actions social
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

          // titre + texte
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
