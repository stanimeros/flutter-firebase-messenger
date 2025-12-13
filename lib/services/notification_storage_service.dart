import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationStorageService {
  static const _notificationsKey = 'notification_history';

  Future<List<NotificationModel>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];
    return notificationsJson
        .map((json) => NotificationModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveNotification(NotificationModel notification) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    notifications.insert(0, notification); // Add to beginning
    // Keep only last 100 notifications
    if (notifications.length > 100) {
      notifications.removeRange(100, notifications.length);
    }
    final notificationsJson = notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_notificationsKey, notificationsJson);
  }

  Future<void> deleteNotification(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    notifications.removeWhere((n) => n.id == notificationId);
    final notificationsJson = notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_notificationsKey, notificationsJson);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }
}

