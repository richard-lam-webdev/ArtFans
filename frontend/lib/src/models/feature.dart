class Feature {
  final String key;
  final String description;
  bool enabled;

  Feature({
    required this.key,
    required this.description,
    required this.enabled,
  });

  factory Feature.fromJson(Map<String, dynamic> json) => Feature(
    key: json['key'] as String,
    description: json['description'] as String,
    enabled: json['enabled'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'description': description,
    'enabled': enabled,
  };
}
