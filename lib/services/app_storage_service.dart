import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_model.dart';
import '../models/topic_model.dart';
import '../models/user_model.dart';
import 'secure_storage_service.dart';

class AppStorageService {
  static const _appsKey = 'saved_apps';
  final _secureStorage = SecureStorageService();

  Future<List<AppModel>> getApps() async {
    final prefs = await SharedPreferences.getInstance();
    final appsJson = prefs.getStringList(_appsKey) ?? [];
    return appsJson
        .map((json) => AppModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveApp(AppModel app) async {
    final prefs = await SharedPreferences.getInstance();
    final apps = await getApps();
    final existingIndex = apps.indexWhere((a) => a.id == app.id);
    if (existingIndex >= 0) {
      apps[existingIndex] = app;
    } else {
      apps.add(app);
    }
    final appsJson = apps.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_appsKey, appsJson);
  }

  Future<void> deleteApp(String appId) async {
    final prefs = await SharedPreferences.getInstance();
    final apps = await getApps();
    apps.removeWhere((a) => a.id == appId);
    final appsJson = apps.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_appsKey, appsJson);
    // Also delete JSON credentials from secure storage
    await _secureStorage.deleteAppCredentials(appId);
  }

  Future<AppModel?> getAppById(String appId) async {
    final apps = await getApps();
    try {
      return apps.firstWhere((a) => a.id == appId);
    } catch (e) {
      return null;
    }
  }

  // Helper methods for topics
  Future<void> addTopic(String appId, TopicModel topic) async {
    final app = await getAppById(appId);
    if (app != null) {
      final updatedTopics = List<TopicModel>.from(app.topics)..add(topic);
      await saveApp(app.copyWith(topics: updatedTopics));
    }
  }

  Future<void> deleteTopic(String appId, String topicId) async {
    final app = await getAppById(appId);
    if (app != null) {
      final updatedTopics = app.topics.where((t) => t.id != topicId).toList();
      await saveApp(app.copyWith(topics: updatedTopics));
    }
  }

  // Helper methods for users
  Future<void> addUser(String appId, UserModel user) async {
    final app = await getAppById(appId);
    if (app != null) {
      final updatedUsers = List<UserModel>.from(app.users)..add(user);
      await saveApp(app.copyWith(users: updatedUsers));
    }
  }

  Future<void> deleteUser(String appId, String userId) async {
    final app = await getAppById(appId);
    if (app != null) {
      final updatedUsers = app.users.where((u) => u.id != userId).toList();
      await saveApp(app.copyWith(users: updatedUsers));
    }
  }
}

