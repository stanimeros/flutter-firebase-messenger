import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_model.dart';
import 'secure_storage_service.dart';

class FCMService {
  final _secureStorage = SecureStorageService();

  Future<String?> _getServerKeyFromJson(String appId) async {
    try {
      // Try to get JSON from secure storage first
      final jsonContent = await _secureStorage.getAppCredentials(appId);
      
      if (jsonContent == null || jsonContent.isEmpty) {
        throw Exception('JSON credentials not found. Please update the app and select the JSON file again.');
      }
      
      final jsonData = jsonDecode(jsonContent) as Map<String, dynamic>;
      
      // Try to find server key in various possible fields
      if (jsonData.containsKey('server_key')) {
        return jsonData['server_key'] as String?;
      }
      if (jsonData.containsKey('serverKey')) {
        return jsonData['serverKey'] as String?;
      }
      if (jsonData.containsKey('fcm_server_key')) {
        return jsonData['fcm_server_key'] as String?;
      }
      
      // If no server key found, we'll need to use OAuth2 with service account
      // For now, return null and throw an error
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> sendNotification({
    required AppModel app,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? topic,
    List<String>? tokens,
  }) async {
    try {
      final serverKey = await _getServerKeyFromJson(app.id);
      if (serverKey == null || serverKey.isEmpty) {
        throw Exception('Server key not found in JSON file. Please ensure the JSON file contains a server_key field with your FCM server key.');
      }

      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
      
      final payload = <String, dynamic>{
        'notification': {
          'title': title,
          'body': body,
          if (imageUrl != null) 'image': imageUrl,
        },
        if (data != null) 'data': data,
      };

      if (topic != null && topic.isNotEmpty) {
        payload['to'] = '/topics/$topic';
      } else if (tokens != null && tokens.isNotEmpty) {
        if (tokens.length == 1) {
          payload['to'] = tokens.first;
        } else {
          payload['registration_ids'] = tokens;
        }
      } else {
        throw Exception('Either topic or tokens must be provided');
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] != null && responseData['success'] == 1) {
          return true;
        }
        if (responseData['message_id'] != null) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      rethrow;
    }
  }
}

