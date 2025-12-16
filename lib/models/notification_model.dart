import 'package:fire_message/models/app_model.dart';

class NotificationModel {
  final String id;
  final AppModel app;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final String? topic;
  final String? condition;
  final List<String>? tokens;
  final DateTime createdAt;
  final bool sent;
  final String? error;
  final String? nickname;

  NotificationModel({
    required this.id,
    required this.app,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    this.topic,
    this.condition,
    this.tokens,
    required this.createdAt,
    this.sent = false,
    this.error,
    this.nickname,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'app': app.toJson(),
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'topic': topic,
      'condition': condition,
      'tokens': tokens,
      'createdAt': createdAt.toIso8601String(),
      'sent': sent,
      'error': error,
      'nickname': nickname,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      app: AppModel.fromJson(json['app'] as Map<String, dynamic>),
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['imageUrl'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      topic: json['topic'] as String?,
      condition: json['condition'] as String?,
      tokens: json['tokens'] != null ? List<String>.from(json['tokens']) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sent: json['sent'] as bool? ?? false,
      error: json['error'] as String?,
      nickname: json['nickname'] as String?,
    );
  }

  NotificationModel copyWith({
    String? id,
    AppModel? app,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? topic,
    String? condition,
    List<String>? tokens,
    DateTime? createdAt,
    bool? sent,
    String? error,
    String? nickname,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      app: app ?? this.app,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      topic: topic ?? this.topic,
      condition: condition ?? this.condition,
      tokens: tokens ?? this.tokens,
      createdAt: createdAt ?? this.createdAt,
      sent: sent ?? this.sent,
      error: error ?? this.error,
      nickname: nickname ?? this.nickname,
    );
  }
}

