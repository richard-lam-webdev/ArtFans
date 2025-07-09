import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/content_detail_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/protected_image.dart';
import '../services/admin_content_service.dart';
import '../services/admin_comment_service.dart';

class ContentDetailScreen extends StatefulWidget {
  final String contentId;
  const ContentDetailScreen({Key? key, required this.contentId})
    : super(key: key);

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  late final AdminContentService _adminContentService;
  late final AdminCommentService _adminCommentService;

  @override
  void initState() {
    super.initState();
    _adminContentService = AdminContentService();
    _adminCommentService = AdminCommentService();

    // On charge le contenu + commentaires
    Future.microtask(
      () => context.read<ContentDetailProvider>().load(widget.contentId),
    );
  }

  @override
  void didUpdateWidget(covariant ContentDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.contentId != widget.contentId) {
      // on a navigué vers un autre ID : on recharge
      context.read<ContentDetailProvider>().load(widget.contentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ContentDetailProvider>();

    // 1) Loading
    if (prov.status == ContentDetailStatus.initial ||
        prov.status == ContentDetailStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2) Erreur
    if (prov.status == ContentDetailStatus.error) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => GoRouter.of(context).go('/admin'),
          ),
          title: const Text('Détail du contenu'),
        ),
        body: Center(child: Text('Erreur : ${prov.errorMessage}')),
      );
    }

    // 3) Chargé
    final c = prov.content!;
    final comments = prov.comments;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go('/admin'),
        ),
        title: Text(c['title'] as String),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer le contenu',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: const Text('Confirmation'),
                      content: const Text(
                        'Voulez-vous supprimer définitivement ce contenu ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
              );
              if (ok != true) return;

              try {
                await _adminContentService.deleteContent(widget.contentId);
                GoRouter.of(context).go('/admin');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contenu supprimé')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur suppression : $e')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------- Image protégée ---------------
            ProtectedImage(
              contentId: widget.contentId,
              isSubscribed: true, // ou selon votre logique d'abonnement
            ),

            const SizedBox(height: 16),

            // --------------- Titre ---------------
            Text(
              c['title'] as String,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),

            // --------------- Auteur & date ---------------
            Text(
              'par ${(c['author_name'] as String?)?.isNotEmpty == true ? c['author_name'] : 'Anonyme'}'
              ' • ${c['created_at']}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),
            const Divider(),

            // --------------- Commentaires ---------------
            Text(
              'Commentaires',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),

            if (comments.isEmpty)
              const Text('Aucun commentaire pour ce contenu.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, i) {
                  final cm = comments[i];
                  final text = cm['text'] as String? ?? '';
                  final date = cm['created_at'] as String? ?? '';
                  final authorName = cm['author_name'] as String? ?? 'Anonyme';
                  final commentId = cm['id'].toString();

                  return ListTile(
                    leading: const Icon(Icons.comment_outlined),
                    title: Text(text),
                    subtitle: Text('par $authorName • $date'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Supprimer le commentaire',
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: const Text('Confirmation'),
                                content: const Text(
                                  'Supprimer ce commentaire ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                        );
                        if (ok != true) return;
                        try {
                          await _adminCommentService.deleteComment(commentId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Commentaire supprimé'),
                            ),
                          );
                          await prov.load(widget.contentId);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur : $e')),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
