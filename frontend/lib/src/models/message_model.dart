// lib/models/message_model.dart

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime sentAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.sentAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['ID'] ?? json['id'] ?? '',
      senderId: json['SenderID'] ?? json['senderId'] ?? '',
      receiverId: json['ReceiverID'] ?? json['receiverId'] ?? '',
      text: json['Text'] ?? json['text'] ?? '',
      sentAt: DateTime.parse(json['SentAt'] ?? json['sentAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'sentAt': sentAt.toIso8601String(),
    };
  }
}

class ConversationPreview {
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSender;

  ConversationPreview({
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSender,
  });

  factory ConversationPreview.fromJson(Map<String, dynamic> json) {
    return ConversationPreview(
      otherUserId: json['otherUserId'] ?? '',
      otherUserName: json['otherUserName'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(json['lastMessageTime'] ?? DateTime.now().toIso8601String()),
      lastMessageSender: json['lastMessageSender'] ?? '',
    );
  }
}