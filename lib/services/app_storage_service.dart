import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_model.dart';
import '../models/topic_model.dart';
import '../models/device_model.dart';
import '../models/condition_model.dart';
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

  Future<void> updateTopic(String appId, TopicModel topic) async {
    final app = await getAppById(appId);
    if (app != null) {
      final updatedTopics = app.topics.map((t) => t.id == topic.id ? topic : t).toList();
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

  // Helper methods for devices
  Future<void> addDevice(String appId, DeviceModel device) async {
    final app = await getAppById(appId);
    if (app != null) {
      final updatedDevices = List<DeviceModel>.from(app.devices)..add(device);
      await saveApp(app.copyWith(devices: updatedDevices));
    }
  }

  Future<void> updateDevice(String appId, DeviceModel device) async {
    final app = await getAppById(appId);
    if (app != null) {
      final updatedDevices = app.devices.map((d) => d.id == device.id ? device : d).toList();
      await saveApp(app.copyWith(devices: updatedDevices));
    }
  }

  Future<void> deleteDevice(String appId, String deviceId) async {
    final app = await getAppById(appId);
    if (app != null) {
      final updatedDevices = app.devices.where((u) => u.id != deviceId).toList();
      await saveApp(app.copyWith(devices: updatedDevices));
    }
  }

  // Legacy support - keep for backward compatibility
  Future<void> addUser(String appId, DeviceModel user) async {
    await addDevice(appId, user);
  }

  Future<void> deleteUser(String appId, String userId) async {
    await deleteDevice(appId, userId);
  }

  // Helper methods for conditions
  Future<void> addCondition(String appId, ConditionModel condition) async {
    final app = await getAppById(appId);
    if (app != null) {
      final updatedConditions = List<ConditionModel>.from(app.conditions)..add(condition);
      await saveApp(app.copyWith(conditions: updatedConditions));
    }
  }

  Future<void> deleteCondition(String appId, String conditionId) async {
    final app = await getAppById(appId);
    if (app != null) {
      final updatedConditions = app.conditions.where((c) => c.id != conditionId).toList();
      await saveApp(app.copyWith(conditions: updatedConditions));
    }
  }

  Future<void> updateCondition(String appId, ConditionModel condition) async {
    final app = await getAppById(appId);
    if (app != null) {
      final updatedConditions = app.conditions.map((c) => c.id == condition.id ? condition : c).toList();
      await saveApp(app.copyWith(conditions: updatedConditions));
    }
  }
}

