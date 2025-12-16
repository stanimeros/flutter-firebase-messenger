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
  final String? token;
  final DateTime createdAt;
  final bool sent;
  final String nickname;
  final String? resultCode;
  final String? resultMessage;

  NotificationModel({
    required this.id,
    required this.app,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    this.topic,
    this.condition,
    this.token,
    required this.createdAt,
    this.sent = false,
    required this.nickname,
    this.resultCode,
    this.resultMessage,
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
      'token': token,
      'createdAt': createdAt.toIso8601String(),
      'sent': sent,
      'nickname': nickname,
      'resultCode': resultCode,
      'resultMessage': resultMessage,
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
      token: json['token'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sent: json['sent'] as bool? ?? false,
      nickname: json['nickname'] as String? ?? '',
      resultCode: json['resultCode'] as String?,
      resultMessage: json['resultMessage'] as String?,
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
    String? token,
    DateTime? createdAt,
    bool? sent,
    String? nickname,
    String? resultCode,
    String? resultMessage,
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
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      sent: sent ?? this.sent,
      nickname: nickname ?? this.nickname,
      resultCode: resultCode ?? this.resultCode,
      resultMessage: resultMessage ?? this.resultMessage,
    );
  }
}

