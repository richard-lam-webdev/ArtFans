import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/message_model.dart';

class MessageService {
  final _storage = const FlutterSecureStorage();
  final String _baseUrl='';  


  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<MessageModel> sendMessage(String receiverId, String text) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token JWT manquant");

    final response = await http.post(
      Uri.parse("$_baseUrl/api/messages"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'receiverId': receiverId, 'text': text}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return MessageModel.fromJson(data['message']);
    } else {
      throw Exception("Erreur ${response.statusCode} : ${response.body}");
    }
  }

  Future<List<ConversationPreview>> getConversations() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token JWT manquant");

    final response = await http.get(
      Uri.parse("$_baseUrl/api/messages"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final conversations = data['conversations'] as List;
      return conversations.map((c) => ConversationPreview.fromJson(c)).toList();
    } else {
      throw Exception("Erreur ${response.statusCode} : ${response.body}");
    }
  }

  Future<List<MessageModel>> getConversation(String userId) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token JWT manquant");

    final response = await http.get(
      Uri.parse("$_baseUrl/api/messages/$userId"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final messages = data['messages'] as List;
      return messages.map((m) => MessageModel.fromJson(m)).toList();
    } else {
      throw Exception("Erreur ${response.statusCode} : ${response.body}");
    }
  }
}
