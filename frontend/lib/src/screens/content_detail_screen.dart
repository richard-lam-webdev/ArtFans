import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/content_detail_provider.dart';
import '../widgets/protected_image.dart';
import '../services/admin_comment_service.dart';

class ContentDetailScreen extends StatefulWidget {
  final String contentId;
  const ContentDetailScreen({super.key, required this.contentId});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  late final AdminCommentService _adminCommentService;

  @override
  void initState() {
    super.initState();
    _adminCommentService = AdminCommentService();

    // Charge le contenu + commentaires dès la première frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ContentDetailProvider>().load(widget.contentId);
    });
  }

  @override
  void didUpdateWidget(covariant ContentDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.contentId != widget.contentId) {
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
            onPressed: () => context.go('/admin'),
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
          onPressed: () => context.go('/admin'),
        ),
        title: Text(c['title'] as String),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image protégée
            ProtectedImage(contentId: widget.contentId, isSubscribed: true),
            const SizedBox(height: 16),

            // Titre
            Text(
              c['title'] as String,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            const Divider(),

            // Commentaires
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
                        // 1. Capture les objets dépendants du contexte AVANT tout await
                        final messenger = ScaffoldMessenger.of(context);
                        final detailProv =
                            context.read<ContentDetailProvider>();

                        // 2. Boîte de dialogue
                        final ok = await showDialog<bool>(
                          context: context,
                          builder:
                              (dialogCtx) => AlertDialog(
                                title: const Text('Confirmation'),
                                content: const Text(
                                  'Supprimer ce commentaire ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () =>
                                            Navigator.of(dialogCtx).pop(false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(dialogCtx).pop(true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                        );
                        if (ok != true) return;

                        try {
                          // 3. Suppression côté API
                          await _adminCommentService.deleteComment(commentId);

                          // 4. Feedback utilisateur (plus d’accès direct à context)
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Commentaire supprimé'),
                            ),
                          );

                          // 5. Recharge les données
                          await detailProv.load(widget.contentId);
                        } catch (e) {
                          messenger.showSnackBar(
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
