import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';

class MessageProvider extends ChangeNotifier {
  /* -------------------- champs privés -------------------- */

  final MessageService _messageService = MessageService();

  List<ConversationPreview> _conversations = [];
  final Map<String, List<MessageModel>> _messagesCache = {};
  final Map<String, DateTime> _lastReadAt = {};

  bool _isLoading = false;
  Timer? _refreshTimer;

  String? _currentUserId;
  String? _currentChatUserId;

  /* -------------------- getters publics ------------------ */

  String? get currentUserId => _currentUserId;
  List<ConversationPreview> get conversations => _conversations;
  bool get isLoading => _isLoading;

  int get totalUnreadCount {
    int count = 0;
    for (final c in _conversations) {
      if (hasUnreadMessages(c.otherUserId)) count++;
    }
    return count;
  }

  /* -------------------- logique non-lu -------------------- */

  bool hasUnreadMessages(String userId) {
    final conv = _conversations.firstWhere(
      (c) => c.otherUserId == userId,
      orElse:
          () => ConversationPreview(
            otherUserId: '',
            otherUserName: '',
            lastMessage: '',
            lastMessageTime: DateTime.now(),
            lastMessageSender: '',
          ),
    );

    final lastRead = _lastReadAt[userId];
    return _currentUserId != null &&
        conv.lastMessageSender != _currentUserId &&
        (lastRead == null || conv.lastMessageTime.isAfter(lastRead));
  }

  void markConversationAsRead(String userId) {
    _lastReadAt[userId] = DateTime.now();
    notifyListeners();
  }

  /* -------------------- API publique ---------------------- */

  List<MessageModel> getMessages(String userId) => _messagesCache[userId] ?? [];

  Future<void> initialize() async {
    _currentUserId = await AuthService().getUserId();
    debugPrint('### currentUserId = $_currentUserId');
    notifyListeners();
  }

  void setCurrentChat(String? userId) {
    _currentChatUserId = userId;
    if (userId != null) markConversationAsRead(userId);
  }

  /* -------------------- rafraîchissements ----------------- */

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      refreshConversations(silent: true);
      for (final userId in _messagesCache.keys) {
        refreshMessages(userId, silent: true);
      }
    });
  }

  void stopAutoRefresh() => _refreshTimer?.cancel();

  Future<void> refreshConversations({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _conversations = await _messageService.getConversations();

      for (final c in _conversations) {
        final lastRead = _lastReadAt[c.otherUserId];
        final fromOther = c.lastMessageSender != _currentUserId;
        if (fromOther &&
            lastRead != null &&
            c.lastMessageTime.isAfter(lastRead)) {
          _lastReadAt.remove(c.otherUserId);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMessages(String userId, {bool silent = false}) async {
    try {
      final messages = await _messageService.getConversation(userId);
      _messagesCache[userId] = messages;

      if (_currentChatUserId != userId &&
          messages.isNotEmpty &&
          messages.last.senderId != _currentUserId) {
        _lastReadAt.remove(userId);
      }

      notifyListeners();
    } catch (_) {}
  }

  Future<void> sendMessage(String receiverId, String text) async {
    final msg = await _messageService.sendMessage(receiverId, text);

    _messagesCache.putIfAbsent(receiverId, () => []).add(msg);
    notifyListeners();

    refreshConversations(silent: true);
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
