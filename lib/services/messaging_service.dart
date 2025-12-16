import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../models/app_model.dart';
import 'secure_storage_service.dart';

class MessagingService {
  final _secureStorage = SecureStorageService();
  static const _fcmScope = 'https://www.googleapis.com/auth/firebase.messaging';

  Future<String> _getAccessToken(String appId) async {
    try {
      // Get Google key model from secure storage
      final serviceAccount = await _secureStorage.getAppCredentials(appId);
      
      if (serviceAccount == null) {
        throw Exception('JSON credentials not found. Please update the app and select the JSON file again.');
      }
      
      // Validate the model
      if (serviceAccount.isEmpty) {
        throw Exception('Invalid service account JSON. Missing required fields: project_id, client_email, or private_key.');
      }
      
      // Create service account credentials from JSON string
      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      
      // Obtain authenticated client using clientViaServiceAccount
      final client = await clientViaServiceAccount(
        credentials,
        [_fcmScope],
      );
      
      // Get access token from the client's credentials
      final accessToken = client.credentials.accessToken.data;
      
      // Close the client as we only need the token
      client.close();
      
      if (accessToken.isEmpty) {
        throw Exception('Failed to obtain access token from service account.');
      }
      
      return accessToken;
    } catch (e) {
      throw Exception('Failed to generate access token: $e');
    }
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
  }) async {
    try {
      // Get OAuth 2.0 access token
      final accessToken = await _getAccessToken(app.id);

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
          'Authorization': 'Bearer $accessToken',
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

