// lib/src/models/creator.dart

class Creator {
  Creator({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.isFollowed,
  });

  final int id;
  final String username;
  final String avatarUrl;
  bool isFollowed;

  factory Creator.fromJson(Map<String, dynamic> json) => Creator(
    id: json['id'] as int,
    username: json['username'] as String,
    avatarUrl: json['avatar_url'] as String? ?? '',
    isFollowed: json['is_followed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatar_url': avatarUrl,
    'is_followed': isFollowed,
  };
}
