class AppModel {
  final String id;
  final String name;
  final String packageName;
  final String jsonFilePath;
  final String? logoFilePath;
  final DateTime createdAt;

  AppModel({
    required this.id,
    required this.name,
    required this.packageName,
    required this.jsonFilePath,
    this.logoFilePath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'packageName': packageName,
      'jsonFilePath': jsonFilePath,
      'logoFilePath': logoFilePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: json['id'] as String,
      name: json['name'] as String,
      packageName: json['packageName'] as String,
      jsonFilePath: json['jsonFilePath'] as String? ?? json['serverKey'] as String? ?? '',
      logoFilePath: json['logoFilePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  AppModel copyWith({
    String? id,
    String? name,
    String? packageName,
    String? jsonFilePath,
    String? logoFilePath,
    DateTime? createdAt,
  }) {
    return AppModel(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      jsonFilePath: jsonFilePath ?? this.jsonFilePath,
      logoFilePath: logoFilePath ?? this.logoFilePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

