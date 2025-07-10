// lib/src/providers/content_detail_provider.dart

import 'package:flutter/foundation.dart';
import '../services/content_service.dart';
import '../services/content_service.dart' show ContentService;
import '../services/comment_service.dart';

enum ContentDetailStatus { initial, loading, loaded, error }

class ContentDetailProvider extends ChangeNotifier {
  final ContentService _contentService;
  final CommentService _commentService;

  ContentDetailProvider({
    required ContentService contentService,
    required CommentService commentService,
  }) : _contentService = contentService,
       _commentService = commentService;

  ContentDetailStatus _status = ContentDetailStatus.initial;
  Map<String, dynamic>? _content;
  List<Map<String, dynamic>> _comments = [];
  String? _errorMessage;

  ContentDetailStatus get status => _status;
  Map<String, dynamic>? get content => _content;
  List<Map<String, dynamic>> get comments => _comments;
  String? get errorMessage => _errorMessage;

  /// Charge le contenu + ses commentaires
  Future<void> load(String contentId) async {
    _status = ContentDetailStatus.loading;
    notifyListeners();
    try {
      // Méthode aplatie pour l'écran détail
      final detail = await _contentService.getContentDetailById(contentId);

      final cms = await _commentService.fetchComments(contentId);

      _content = detail;
      _comments = cms;
      _status = ContentDetailStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = ContentDetailStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }
}
