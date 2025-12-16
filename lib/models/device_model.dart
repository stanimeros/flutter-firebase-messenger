class DeviceModel {
  final String id;
  final String name;
  final String notificationToken;
  final DateTime createdAt;

  DeviceModel({
    required this.id,
    required this.name,
    required this.notificationToken,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'notificationToken': notificationToken,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      notificationToken: json['notificationToken'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
