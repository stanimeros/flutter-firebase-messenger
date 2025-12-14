class TopicModel {
  final String id;
  final String appId;
  final String name;
  final DateTime createdAt;

  TopicModel({
    required this.id,
    required this.appId,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appId': appId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      appId: json['appId'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
