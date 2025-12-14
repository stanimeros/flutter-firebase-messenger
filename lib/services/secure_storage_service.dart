import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _credentialsKey = 'firebase_credentials';

  // Per-app credentials storage
  String _getAppCredentialsKey(String appId) => 'app_credentials_$appId';

  Future<void> saveCredentials(String jsonContent) async {
    await _storage.write(key: _credentialsKey, value: jsonContent);
  }

  Future<String?> getCredentials() async {
    return await _storage.read(key: _credentialsKey);
  }

  Future<bool> hasCredentials() async {
    final credentials = await getCredentials();
    return credentials != null && credentials.isNotEmpty;
  }

  Future<void> deleteCredentials() async {
    await _storage.delete(key: _credentialsKey);
  }

  Future<Map<String, dynamic>?> getCredentialsAsMap() async {
    final credentials = await getCredentials();
    if (credentials == null) return null;
    try {
      return jsonDecode(credentials) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Per-app methods
  Future<void> saveAppCredentials(String appId, String jsonContent) async {
    await _storage.write(key: _getAppCredentialsKey(appId), value: jsonContent);
  }

  Future<String?> getAppCredentials(String appId) async {
    return await _storage.read(key: _getAppCredentialsKey(appId));
  }

  Future<Map<String, dynamic>?> getAppCredentialsAsMap(String appId) async {
    final credentials = await getAppCredentials(appId);
    if (credentials == null) return null;
    try {
      return jsonDecode(credentials) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteAppCredentials(String appId) async {
    await _storage.delete(key: _getAppCredentialsKey(appId));
  }

  Future<bool> hasAppCredentials(String appId) async {
    final credentials = await getAppCredentials(appId);
    return credentials != null && credentials.isNotEmpty;
  }
}

