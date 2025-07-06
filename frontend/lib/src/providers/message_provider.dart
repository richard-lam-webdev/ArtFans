// lib/providers/message_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();
  
  List<ConversationPreview> _conversations = [];
  Map<String, List<MessageModel>> _messagesCache = {};
  Set<String> _readConversations = {};
  bool _isLoading = false;
  Timer? _refreshTimer;
  String? _currentUserId;
  String? _currentChatUserId;
  String? get currentUserId => _currentUserId;
  List<ConversationPreview> get conversations => _conversations;
  bool get isLoading => _isLoading;
  
  int get totalUnreadCount {
    int count = 0;
    for (var conversation in _conversations) {
      if (hasUnreadMessages(conversation.otherUserId)) {
        count++;
      }
    }
    return count;
  }
  
  bool hasUnreadMessages(String userId) {
    final conversation = _conversations.firstWhere(
      (c) => c.otherUserId == userId,
      orElse: () => ConversationPreview(
        otherUserId: '',
        otherUserName: '',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        lastMessageSender: '',
      ),
    );
    
    return _currentUserId != null && 
           conversation.lastMessageSender != _currentUserId &&
           !_readConversations.contains(userId);
  }
  
  List<MessageModel> getMessages(String userId) {
    return _messagesCache[userId] ?? [];
  }

  Future<void> initialize() async {
    _currentUserId = await AuthService().getUserId();
    debugPrint('### currentUserId = $_currentUserId');   // ← log
    notifyListeners();
  }

  void setCurrentChat(String? userId) {
    _currentChatUserId = userId;
    if (userId != null) {
      markConversationAsRead(userId);
    }
  }

  void markConversationAsRead(String userId) {
    _readConversations.add(userId);
    notifyListeners();
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    refreshConversations(silent: true);
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      refreshConversations(silent: true);
      for (String userId in _messagesCache.keys) {
        refreshMessages(userId, silent: true);
      }
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  Future<void> refreshConversations({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    
    try {
      _conversations = await _messageService.getConversations();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMessages(String userId, {bool silent = false}) async {
    try {
      final messages = await _messageService.getConversation(userId);
      _messagesCache[userId] = messages;
      notifyListeners();
    } catch (e) {
      // Silencieux
    }
  }

  Future<void> sendMessage(String receiverId, String text) async {
    final message = await _messageService.sendMessage(receiverId, text);
    
    if (_messagesCache.containsKey(receiverId)) {
      _messagesCache[receiverId]!.add(message);
      notifyListeners();
    }
    
    refreshConversations(silent: true);
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}