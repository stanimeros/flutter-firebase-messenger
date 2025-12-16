import 'topic_model.dart';
import 'device_model.dart';
import 'condition_model.dart';

class AppModel {
  final String id;
  final String name;
  final String packageName;
  final String? imageData; // Base64 encoded image data
  final DateTime createdAt;
  final List<TopicModel> topics;
  final List<DeviceModel> devices;
  final List<ConditionModel> conditions;

  AppModel({
    required this.id,
    required this.name,
    required this.packageName,
    this.imageData,
    required this.createdAt,
    List<TopicModel>? topics,
    List<DeviceModel>? devices,
    List<ConditionModel>? conditions,
  })  : topics = topics ?? [],
        devices = devices ?? [],
        conditions = conditions ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'packageName': packageName,
      'imageData': imageData,
      'createdAt': createdAt.toIso8601String(),
      'topics': topics.map((t) => t.toJson()).toList(),
      'devices': devices.map((u) => u.toJson()).toList(),
      'conditions': conditions.map((c) => c.toJson()).toList(),
    };
  }

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: json['id'] as String,
      name: json['name'] as String,
      packageName: json['packageName'] as String,
      imageData: json['imageData'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      topics: (json['topics'] as List<dynamic>?)
          ?.map((t) => TopicModel.fromJson(t as Map<String, dynamic>))
          .toList() ?? [],
      devices: (json['devices'] as List<dynamic>?)
          ?.map((u) => DeviceModel.fromJson(u as Map<String, dynamic>))
          .toList() ?? [],
      conditions: (json['conditions'] as List<dynamic>?)
          ?.map((c) => ConditionModel.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  AppModel copyWith({
    String? id,
    String? name,
    String? packageName,
    String? imageData,
    DateTime? createdAt,
    List<TopicModel>? topics,
    List<DeviceModel>? devices,
    List<ConditionModel>? conditions,
  }) {
    return AppModel(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      imageData: imageData ?? this.imageData,
      createdAt: createdAt ?? this.createdAt,
      topics: topics ?? this.topics,
      devices: devices ?? this.devices,
      conditions: conditions ?? this.conditions,
    );
  }
}

