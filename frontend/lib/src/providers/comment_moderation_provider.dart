// lib/src/providers/comment_moderation_provider.dart

import 'package:flutter/foundation.dart';
import '../services/admin_comment_service.dart';

/// États possibles du provider de modération de commentaires.
enum CommentModerationStatus { initial, loading, loaded, error }

class CommentModerationProvider extends ChangeNotifier {
  final AdminCommentService _service;

  CommentModerationProvider({required AdminCommentService service})
    : _service = service;

  CommentModerationStatus _status = CommentModerationStatus.initial;
  List<Map<String, dynamic>> _comments = [];
  String? _errorMessage;

  CommentModerationStatus get status => _status;
  List<Map<String, dynamic>> get comments => _comments;
  String? get errorMessage => _errorMessage;

  /// Récupère la page [page] de commentaires (taille [pageSize]),
  /// puis notifie l’UI.
  Future<void> fetchComments({int page = 1, int pageSize = 20}) async {
    _status = CommentModerationStatus.loading;
    notifyListeners();
    try {
      final list = await _service.fetchComments(page: page, pageSize: pageSize);
      _comments = list;
      _status = CommentModerationStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = CommentModerationStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  /// Supprime le commentaire d’ID [id], puis recharge la liste.
  Future<void> deleteComment(String id) async {
    _status = CommentModerationStatus.loading;
    notifyListeners();
    try {
      await _service.deleteComment(id);
      // On rafraîchit la page courante (ici page 1) :
      await fetchComments();
    } catch (e) {
      _status = CommentModerationStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}
