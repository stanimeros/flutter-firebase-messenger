class AppModel {
  final String id;
  final String name;
  final String packageName;
  final String? imageData; // Base64 encoded image data
  final DateTime createdAt;

  AppModel({
    required this.id,
    required this.name,
    required this.packageName,
    this.imageData,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'packageName': packageName,
      'imageData': imageData,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: json['id'] as String,
      name: json['name'] as String,
      packageName: json['packageName'] as String,
      imageData: json['imageData'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

