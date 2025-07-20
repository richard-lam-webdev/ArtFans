import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/comment_service.dart';

class CommentsSheet extends StatefulWidget {
  final String contentId;
  const CommentsSheet({super.key, required this.contentId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentSvc = CommentService();
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;

  String? _replyToId;
  String? _replyToAuthor;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    try {
      _comments = await _commentSvc.fetchComments(widget.contentId);
    } catch (_) {
      _comments = [];
    }
    setState(() => _loading = false);
  }

  Future<void> _postComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    try {
      await _commentSvc.postComment(
        widget.contentId,
        text,
        parentId: _replyToId,
      );
      if (!mounted) return;
      _ctrl.clear();
      _replyToId = null;
      _replyToAuthor = null;
      _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur commentaire : $e')));
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> c) async {
    final id = c['id'] as String;
    final already = c['liked_by_me'] as bool? ?? false;

    setState(() {
      c['liked_by_me'] = !already;
      c['like_count'] = (c['like_count'] as int? ?? 0) + (already ? -1 : 1);
    });

    try {
      if (already) {
        await _commentSvc.unlikeComment(id);
      } else {
        await _commentSvc.likeComment(id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        c['liked_by_me'] = already;
        c['like_count'] = (c['like_count'] as int? ?? 0) + (already ? 1 : -1);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur like : $e')));
    }
  }

  void _startReply(Map<String, dynamic> c) {
    final rawName = c['author_name'] as String?;
    final rawId = c['author_id'] as String?;
    final name = rawName ?? rawId ?? 'Inconnu';

    setState(() {
      _replyToId = c['id'] as String;
      _replyToAuthor = name;
      _ctrl.text = '@$name ';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else if (_comments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Aucun commentaire."),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _comments.length,
                  itemBuilder: (ctx, i) {
                    final c = _comments[i];

                    final rawName = c['author_name'] as String?;
                    final rawId = c['author_id'] as String?;
                    final name = rawName ?? rawId ?? 'Inconnu';
                    final initial =
                        name.isNotEmpty ? name.substring(0, 1) : '?';

                    final indent = c['parent_id'] != null ? 24.0 : 0.0;

                    final createdAtRaw = c['created_at'] as String? ?? '';
                    final createdAt =
                        DateTime.tryParse(createdAtRaw) ?? DateTime.now();

                    final likeCount = c['like_count'] as int? ?? 0;
                    final likedByMe = c['liked_by_me'] as bool? ?? false;

                    return Padding(
                      padding: EdgeInsets.only(left: indent),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(initial)),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['text'] as String),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.yMMMd().add_jm().format(createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$likeCount'),
                            IconButton(
                              icon: Icon(
                                likedByMe
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                              ),
                              color: likedByMe ? Colors.red : null,
                              onPressed: () => _toggleLike(c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.reply),
                              onPressed: () => _startReply(c),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (_replyToAuthor != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Text('Répondre à @$_replyToAuthor'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _replyToId = null;
                          _replyToAuthor = null;
                          _ctrl.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),

            const Divider(height: 1),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un commentaire…',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _postComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
