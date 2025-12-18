import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_model.dart';
import 'secure_storage_service.dart';
import 'token_service.dart';

class MessagingService {
  final _secureStorage = SecureStorageService();
  final _tokenService = TokenService();

  Future<String> _getAccessToken(String appId) async {
    return _tokenService.getFcmAccessToken(appId);
  }

  Future<bool> sendNotification({
    required AppModel app,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? topic,
    String? condition,
    String? token,
    String? accessToken,
  }) async {
    try {
      // Use provided token or generate one
      final fcmToken = accessToken ?? await _getAccessToken(app.id);

      // Get service account data to extract project_id
      final serviceAccount = await _secureStorage.getAppCredentials(app.id);
      final projectId = serviceAccount?['project_id'];
      
      // Use FCM HTTP v1 API endpoint
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');
      
      // Build the message payload according to v1 API format
      final message = <String, dynamic>{
        'notification': {
          'title': title,
          'body': body,
        },
        if (data != null) 'data': data,
      };

      // Add image URL to platform-specific fields if provided
      if (imageUrl != null && imageUrl.isNotEmpty) {
        message['android'] = {
          'notification': {
            'image': imageUrl,
          },
        };
        message['apns'] = {
          'payload': {
            'aps': {
              'mutable-content': 1,
            },
          },
          'fcm_options': {
            'image': imageUrl,
          },
        };
        message['webpush'] = {
          'headers': {
            'image': imageUrl,
          },
        };
      }
      
      // Set target (token, topic, or condition)
      if (condition != null && condition.isNotEmpty) {
        message['condition'] = condition;
      } else if (topic != null && topic.isNotEmpty) {
        message['topic'] = topic;
      } else if (token != null && token.isNotEmpty) {
        message['token'] = token;
      } else {
        throw Exception('Either topic, condition, or token must be provided');
      }
      
      final payload = <String, dynamic>{
        'message': message,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $fcmToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        // v1 API returns success with a 'name' field containing the message ID
        if (responseData['name'] != null) {
          return true;
        }
      }
      
      // Log error for debugging
      if (response.statusCode != 200) {
        throw Exception('FCM API error: ${response.statusCode} - ${response.body}');
      }
      
      return false;
    } catch (e) {
      rethrow;
    }
  }
}

