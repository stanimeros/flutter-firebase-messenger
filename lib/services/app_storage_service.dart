import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_model.dart';

class AppStorageService {
  static const _appsKey = 'saved_apps';

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
  }

  Future<AppModel?> getAppById(String appId) async {
    final apps = await getApps();
    try {
      return apps.firstWhere((a) => a.id == appId);
    } catch (e) {
      return null;
    }
  }
}

