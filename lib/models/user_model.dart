class UserModel {
  final String id;
  final String appId;
  final String name;
  final String notificationToken;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.appId,
    required this.name,
    required this.notificationToken,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appId': appId,
      'name': name,
      'notificationToken': notificationToken,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      appId: json['appId'] as String,
      name: json['name'] as String,
      notificationToken: json['notificationToken'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
