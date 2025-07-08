import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/content_service.dart';
import '../providers/subscription_provider.dart';
import '../utils/snackbar_util.dart';
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
  final ContentService _svc = ContentService();
  bool _isLoadingSubscription = false;

  Future<void> _toggleSubscribe() async {
    final subProv = context.read<SubscriptionProvider>();
    final creatorId = widget.content['creator_id']?.toString();
    final creatorName =
        widget.content['creator_name']?.toString() ?? 'ce créateur';

    if (creatorId == null) return;

    // On lit l'état actuel dans le provider
    final currentlySubscribed = subProv.isSubscribed(creatorId);

    // Confirmation
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(
                  currentlySubscribed
                      ? 'Se désabonner de $creatorName'
                      : 'S’abonner à $creatorName',
                ),
                content:
                    currentlySubscribed
                        ? const Text(
                          'Êtes-vous sûr de vouloir vous désabonner ?\n\n'
                          'Vous perdrez l\'accès au contenu premium de ce créateur.',
                        )
                        : const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vous allez vous abonner pour :'),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.euro, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '30€ par mois',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text('Durée : 30 jours'),
                              ],
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 20,
                                ),
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
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentlySubscribed ? Colors.red : null,
                      foregroundColor:
                          currentlySubscribed ? Colors.white : null,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      currentlySubscribed ? 'Se désabonner' : 'Confirmer (30€)',
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    // Si le widget a été démonté ou si l'utilisateur annule, on arrête
    if (!mounted || !confirmed) return;

    setState(() => _isLoadingSubscription = true);

    // Exécution de l'action
    final success =
        currentlySubscribed
            ? await subProv.unsubscribeFromCreator(creatorId)
            : await subProv.subscribeToCreator(creatorId);

    // Vérification après l'appel async
    if (!mounted) return;

    if (success) {
      // Mise à jour du provider
      subProv.setSubscriptionStatus(creatorId, !currentlySubscribed);
      if (mounted) {
        showCustomSnackBar(
          context,
          currentlySubscribed
              ? 'Vous êtes désabonné de $creatorName'
              : 'Abonnement à $creatorName réussi !',
          type: SnackBarType.success,
        );
        widget.onSubscribedChanged();
      }
    } else {
      if (mounted) {
        showCustomSnackBar(
          context,
          subProv.errorMessage ?? 'Erreur lors de la mise à jour',
          type: SnackBarType.error,
        );
      }
    }

    // Désactivation du loader si toujours monté
    if (mounted) {
      setState(() => _isLoadingSubscription = false);
    }
  }

  Future<void> _toggleLike() async {
    final bool currentlyLiked =
        widget.content['liked_by_user'] as bool? ?? false;
    final int currentCount = widget.content['likes_count'] as int? ?? 0;

    final bool newLiked = !currentlyLiked;
    final int newCount = currentlyLiked ? currentCount - 1 : currentCount + 1;

    setState(() {
      widget.content['liked_by_user'] = newLiked;
      widget.content['likes_count'] = newCount;
    });

    try {
      if (!mounted) return;
      if (newLiked) {
        await _svc.likeContent(widget.content['id'] as String);
      } else {
        await _svc.unlikeContent(widget.content['id'] as String);
      }
    } catch (e) {
      // En cas d'erreur, rollback et afficher un SnackBar
      if (!mounted) return;
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
    // Pas d'await, utilisation synchrone du context
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
    final creatorId = widget.content['creator_id']?.toString();
    final isSubscribed =
        creatorId != null
            ? context.watch<SubscriptionProvider>().isSubscribed(creatorId)
            : false;

    final bool liked = widget.content['liked_by_user'] as bool? ?? false;
    final int likeCount = widget.content['likes_count'] as int? ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                widget.content['creator_avatar_url'] ??
                    'https://placehold.co/40x40',
              ),
            ),
            title: Text(widget.content['creator_name'] ?? 'Créateur'),
            trailing:
                _isLoadingSubscription
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : TextButton(
                      onPressed: _toggleSubscribe,
                      child: Text(isSubscribed ? 'Se désabonner' : 'S’abonner'),
                    ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ProtectedImage(
              contentId: widget.content['id'] as String,
              isSubscribed: isSubscribed,
              key: ValueKey('${widget.content['id']}-$isSubscribed'),
            ),
          ),
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
