import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _credentialsKey = 'firebase_credentials';

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
}

