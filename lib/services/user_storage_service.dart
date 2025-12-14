import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserStorageService {
  static const _usersKey = 'saved_users';

  Future<List<UserModel>> getUsers(String appId) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    final allUsers = usersJson
        .map((json) => UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
    return allUsers.where((user) => user.appId == appId).toList();
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getAllUsers();
    final existingIndex = users.indexWhere((u) => u.id == user.id);
    if (existingIndex >= 0) {
      users[existingIndex] = user;
    } else {
      users.add(user);
    }
    final usersJson = users.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList(_usersKey, usersJson);
  }

  Future<void> deleteUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getAllUsers();
    users.removeWhere((u) => u.id == userId);
    final usersJson = users.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList(_usersKey, usersJson);
  }

  Future<List<UserModel>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    return usersJson
        .map((json) => UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }
}
