import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  // Per-app credentials storage
  String _getAppCredentialsKey(String appId) => 'app_credentials_$appId';

  // Per-app methods
  Future<void> saveAppCredentials(String appId, String jsonContent) async {
    await _storage.write(key: _getAppCredentialsKey(appId), value: jsonContent);
  }

  Future<String?> _getAppCredentials(String appId) async {
    return await _storage.read(key: _getAppCredentialsKey(appId));
  }

  /// Gets app credentials as GoogleKeyModel
  Future<Map<String, dynamic>?> getAppCredentials(String appId) async {
    final credentials = await _getAppCredentials(appId);
    if (credentials == null || credentials.isEmpty) return null;
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
    final credentials = await _getAppCredentials(appId);
    return credentials != null && credentials.isNotEmpty;
  }
}

