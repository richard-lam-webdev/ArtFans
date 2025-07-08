// lib/src/models/content.dart

class Content {
  Content({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.creatorName,
  });

  final String id;
  final String title;
  final String thumbnailUrl;
  final String creatorName;

  factory Content.fromJson(Map<String, dynamic> json) => Content(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    thumbnailUrl: json['thumbnail_url'] as String? ?? '',
    creatorName: json['creator_name'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'thumbnail_url': thumbnailUrl,
    'creator_name': creatorName,
  };
}
