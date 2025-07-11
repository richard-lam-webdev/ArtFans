import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../services/content_service.dart';
import '../providers/subscription_provider.dart';
import '../providers/feature_flag_provider.dart';
import '../providers/report_provider.dart';
import '../constants/features.dart';
import '../utils/snackbar_util.dart';
import 'protected_image.dart';
import 'comments_sheet.dart';
// ignore: depend_on_referenced_packages
import 'package:open_file/open_file.dart';


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

  @override
  void initState() {
    super.initState();
    // AJOUT : Initialiser l'état local avec les données du provider
    final creatorId = widget.content['creator_id']?.toString();
    if (creatorId != null) {}
  }

  Future<void> _toggleSubscribe() async {
    final subProv = context.read<SubscriptionProvider>();
    final creatorId = widget.content['creator_id']?.toString();
    final creatorName =
        widget.content['creator_name']?.toString() ?? 'ce créateur';
    if (creatorId == null) return;

    final currentlySubscribed = subProv.isSubscribed(creatorId);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(
                  currentlySubscribed
                      ? 'Se désabonner de $creatorName'
                      : 'S\'abonner à $creatorName',
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

    if (!mounted || !confirmed) return;

    setState(() => _isLoadingSubscription = true);

    final success =
        currentlySubscribed
            ? await subProv.unsubscribeFromCreator(creatorId)
            : await subProv.subscribeToCreator(creatorId);

    if (!mounted) return;

    if (success) {
      subProv.setSubscriptionStatus(creatorId, !currentlySubscribed);
      showCustomSnackBar(
        context,
        currentlySubscribed
            ? 'Vous êtes désabonné de $creatorName'
            : 'Abonnement à $creatorName réussi !',
        type: SnackBarType.success,
      );
      widget.onSubscribedChanged();
      // MODIFICATION : Le provider se met à jour automatiquement dans ses méthodes
      // Pas besoin de setSubscriptionStatus ici, c'est déjà fait dans le provider

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
      showCustomSnackBar(
        context,
        subProv.errorMessage ?? 'Erreur lors de la mise à jour',
        type: SnackBarType.error,
      );
    }

    if (mounted) setState(() => _isLoadingSubscription = false);
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

  Future<void> _downloadContent() async {
  final contentId = widget.content['id'] as String;
  
  try {
    // Appelle la nouvelle méthode
    final localPath = await _svc.downloadContent(contentId);
    
    if (localPath == null) {
      // version Web : le téléchargement a déjà été déclenché
      showCustomSnackBar(
        context,
        'Téléchargement du fichier démarré dans votre navigateur.',
        type: SnackBarType.info,
      );
    } else {
      // version mobile : on a un chemin local
      showCustomSnackBar(
        context,
        'Fichier enregistré : $localPath',
        type: SnackBarType.success,
      );
      // Ouvre le fichier
      await OpenFile.open(localPath);
    }
  } catch (e) {
    showCustomSnackBar(
      context,
      'Erreur de téléchargement : $e',
      type: SnackBarType.error,
    );
  }
}


  Future<void> _reportContent() async {
    final reasons = ['Inapproprié', 'Spam', 'Autre'];
    final selected = await showDialog<String>(
      context: context,
      builder:
          (ctx) => SimpleDialog(
            title: const Text('Signaler ce contenu'),
            children:
                reasons
                    .map(
                      (r) => SimpleDialogOption(
                        child: Text(r),
                        onPressed: () => Navigator.of(ctx).pop(r),
                      ),
                    )
                    .toList(),
          ),
    );
    if (selected == null || !mounted) return;

    try {
      await context.read<ReportProvider>().submitReport(
        widget.content['id'] as String,
        reason: selected,
      );
      if (!mounted) return;
      showCustomSnackBar(
        context,
        'Merci, le contenu a été signalé.',
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
        context,
        'Erreur lors du signalement : $e',
        type: SnackBarType.error,
      );
    }
  }

  void _openChat() {
    final creatorId = widget.content['creator_id']?.toString();
    final creatorName = widget.content['creator_name']?.toString() ?? 'Créateur';
    
    if (creatorId == null) return;
    
    // Vérifier si la fonctionnalité de chat est activée
    final chatEnabled = context.read<FeatureFlagProvider>().features.any(
      (f) => f.key == featureChat && f.enabled,
    );
    
    if (!chatEnabled) {
      showCustomSnackBar(
        context,
        'La messagerie n\'est pas disponible pour le moment',
        type: SnackBarType.info,
      );
      return;
    }
    
    // Naviguer vers l'écran de chat
    context.push('/chat/$creatorId', extra: creatorName);
  }

  @override
  Widget build(BuildContext context) {
    final creatorId = widget.content['creator_id']?.toString();

    // MODIFICATION IMPORTANTE : Utiliser le provider comme source de vérité
    final isSubscribed =
        creatorId != null
            ? context.watch<SubscriptionProvider>().isSubscribed(creatorId)
            : false;

    final bool liked = widget.content['liked_by_user'] as bool? ?? false;
    final int likeCount = widget.content['likes_count'] as int? ?? 0;

    final commentEnabled = context.watch<FeatureFlagProvider>().features.any(
      (f) => f.key == featureComments && f.enabled,
    );
    
    final chatEnabled = context.watch<FeatureFlagProvider>().features.any(
      (f) => f.key == featureChat && f.enabled,
    );

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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton DM (Message)
                if (chatEnabled)
                  IconButton(
                    onPressed: _openChat,
                    icon: const Icon(Icons.message_outlined),
                    tooltip: 'Envoyer un message',
                  ),
                // Bouton S'abonner/Se désabonner
                if (_isLoadingSubscription)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    onPressed: _toggleSubscribe,
                    child: Text(
                      isSubscribed ? 'Se désabonner' : 'S\'abonner',
                    ),
                  ),
              ],
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
                if (commentEnabled) ...[
                  IconButton(
                    icon: const Icon(Icons.comment_outlined),
                    onPressed: _openComments,
                  ),
                  const SizedBox(width: 16),
                ],

                // BOUTON TÉLÉCHARGEMENT CORRIGÉ pour web et mobile
                if (isSubscribed)
                  IconButton(
                    icon: const Icon(Icons.download_outlined),
                    tooltip: 'Télécharger',
                    onPressed: _downloadContent, // Utilise la nouvelle méthode
                  ),

                IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  tooltip: 'Signaler',
                  onPressed: _reportContent,
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