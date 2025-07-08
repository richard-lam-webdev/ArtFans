import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/creator.dart';
import '../providers/auth_provider.dart';

class CreatorTile extends StatefulWidget {
  final Creator creator;
  const CreatorTile({super.key, required this.creator});

  @override
  State<CreatorTile> createState() => _CreatorTileState();
}

class _CreatorTileState extends State<CreatorTile> {
  late bool _isFollowed;

  @override
  void initState() {
    super.initState();
    _isFollowed = widget.creator.isFollowed;
  }

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthProvider>().token!;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(widget.creator.avatarUrl),
      ),
      title: Text(widget.creator.username),
      trailing: TextButton(
        onPressed: () => _toggleFollow(token),
        child: Text(_isFollowed ? 'Abonné' : 'Suivre'),
      ),
      onTap: () => Navigator.of(context).pushNamed('/u/${widget.creator.id}'),
    );
  }

  Future<void> _toggleFollow(String token) async {
    final client = http.Client();
    final url = Uri.parse(
      '${ApiService.baseUrl}/api/subscriptions/${widget.creator.id}',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response =
        _isFollowed
            ? await client.delete(url, headers: headers)
            : await client.post(url, headers: headers);
    client.close();

    if (response.statusCode == 204) {
      setState(() => _isFollowed = !_isFollowed);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur ${response.statusCode}')));
    }
  }
}
