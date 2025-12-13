class AppModel {
  final String id;
  final String name;
  final String packageName;
  final String? serverKey;
  final DateTime createdAt;

  AppModel({
    required this.id,
    required this.name,
    required this.packageName,
    this.serverKey,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'packageName': packageName,
      'serverKey': serverKey,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: json['id'] as String,
      name: json['name'] as String,
      packageName: json['packageName'] as String,
      serverKey: json['serverKey'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  AppModel copyWith({
    String? id,
    String? name,
    String? packageName,
    String? serverKey,
    DateTime? createdAt,
  }) {
    return AppModel(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      serverKey: serverKey ?? this.serverKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

