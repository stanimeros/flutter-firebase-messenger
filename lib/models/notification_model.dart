class NotificationModel {
  final String id;
  final String appId;
  final String appName;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? topic;
  final List<String>? tokens;
  final DateTime createdAt;
  final bool sent;
  final String? error;

  NotificationModel({
    required this.id,
    required this.appId,
    required this.appName,
    required this.title,
    required this.body,
    this.data,
    this.topic,
    this.tokens,
    required this.createdAt,
    this.sent = false,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appId': appId,
      'appName': appName,
      'title': title,
      'body': body,
      'data': data,
      'topic': topic,
      'tokens': tokens,
      'createdAt': createdAt.toIso8601String(),
      'sent': sent,
      'error': error,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      appId: json['appId'] as String,
      appName: json['appName'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      topic: json['topic'] as String?,
      tokens: json['tokens'] != null ? List<String>.from(json['tokens']) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sent: json['sent'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }
}

