import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/comment_moderation_provider.dart';

class CommentsModerationScreen extends StatefulWidget {
  const CommentsModerationScreen({super.key});

  @override
  State<CommentsModerationScreen> createState() =>
      _CommentsModerationScreenState();
}

class _CommentsModerationScreenState extends State<CommentsModerationScreen> {
  int _page = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPage();
    });
  }

  Future<void> _loadPage() async {
    try {
      await context.read<CommentModerationProvider>().fetchComments(
        page: _page,
        pageSize: _pageSize,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CommentModerationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Modération des Commentaires')),
      body: _buildBody(prov),
    );
  }

  Widget _buildBody(CommentModerationProvider prov) {
    if (prov.status == CommentModerationStatus.loading ||
        prov.status == CommentModerationStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.status == CommentModerationStatus.error) {
      return Center(child: Text('Erreur : ${prov.errorMessage}'));
    }

    final comments = prov.comments;
    if (comments.isEmpty) {
      return const Center(child: Text('Aucun commentaire à modérer.'));
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Auteur')),
                DataColumn(label: Text('Contenu')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Actions')),
              ],
              rows:
                  comments.map((c) {
                    final id = c['id'].toString();
                    final authorName = c['author_name'] as String? ?? 'Anonyme';
                    final text = c['text'] as String? ?? '';
                    final date = c['created_at'] as String? ?? '';

                    return DataRow(
                      cells: [
                        DataCell(Text(authorName)),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(date)),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Supprimer',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (dialogContext) => AlertDialog(
                                      title: const Text(
                                        'Confirmer la suppression',
                                      ),
                                      content: const Text(
                                        'Voulez-vous vraiment supprimer ce commentaire ?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                dialogContext,
                                              ).pop(false),
                                          child: const Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                dialogContext,
                                              ).pop(true),
                                          child: const Text('Supprimer'),
                                        ),
                                      ],
                                    ),
                              );

                              if (!mounted || confirm != true) return;

                              try {
                                await context
                                    .read<CommentModerationProvider>()
                                    .deleteComment(id);

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Commentaire supprimé'),
                                  ),
                                );

                                await _loadPage();
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erreur : $e')),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    _page > 1
                        ? () async {
                          setState(() => _page--);
                          await _loadPage();
                        }
                        : null,
              ),
              Text('Page $_page'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    comments.length == _pageSize
                        ? () async {
                          setState(() => _page++);
                          await _loadPage();
                        }
                        : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
