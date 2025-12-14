class AppModel {
  final String id;
  final String name;
  final String packageName;
  final String? logoImageData; // Base64 encoded image data
  final DateTime createdAt;

  AppModel({
    required this.id,
    required this.name,
    required this.packageName,
    this.logoImageData,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'packageName': packageName,
      'logoImageData': logoImageData,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: json['id'] as String,
      name: json['name'] as String,
      packageName: json['packageName'] as String,
      logoImageData: json['logoImageData'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  AppModel copyWith({
    String? id,
    String? name,
    String? packageName,
    String? jsonFilePath,
    String? logoImageData,
    DateTime? createdAt,
  }) {
    return AppModel(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      logoImageData: logoImageData ?? this.logoImageData,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

