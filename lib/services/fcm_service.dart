import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../models/app_model.dart';
import 'secure_storage_service.dart';

class FCMService {
  final _secureStorage = SecureStorageService();
  static const _fcmScope = 'https://www.googleapis.com/auth/firebase.messaging';

  Future<Map<String, dynamic>> _getServiceAccountData(String appId) async {
    // Get JSON from secure storage (same approach as create_app_screen)
    final jsonContent = await _secureStorage.getAppCredentials(appId);
    
    if (jsonContent == null || jsonContent.isEmpty) {
      throw Exception('JSON credentials not found. Please update the app and select the JSON file again.');
    }
    
    // Parse JSON the same way as create_app_screen
    final jsonData = jsonDecode(jsonContent) as Map<String, dynamic>;
    
    // Extract required fields from service account JSON
    final projectId = jsonData['project_id'] as String?;
    final clientEmail = jsonData['client_email'] as String?;
    final privateKey = jsonData['private_key'] as String?;
    
    if (projectId == null || clientEmail == null || privateKey == null) {
      throw Exception('Invalid service account JSON. Missing required fields: project_id, client_email, or private_key.');
    }
    
    return {
      'project_id': projectId,
      'client_email': clientEmail,
      'private_key': privateKey,
      'json': jsonData, // Keep full JSON for ServiceAccountCredentials.fromJson
    };
  }

  Future<String> _getAccessToken(String appId) async {
    try {
      // Get JSON content from secure storage (same approach as create_app_screen)
      final jsonContent = await _secureStorage.getAppCredentials(appId);
      
      if (jsonContent == null || jsonContent.isEmpty) {
        throw Exception('JSON credentials not found. Please update the app and select the JSON file again.');
      }
      
      // Parse JSON to get project_id for validation
      final jsonData = jsonDecode(jsonContent) as Map<String, dynamic>;
      if (jsonData['project_id'] == null || jsonData['client_email'] == null || jsonData['private_key'] == null) {
        throw Exception('Invalid service account JSON. Missing required fields: project_id, client_email, or private_key.');
      }
      
      // Create service account credentials from JSON string
      final credentials = ServiceAccountCredentials.fromJson(jsonContent);
      
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
    List<String>? tokens,
  }) async {
    try {
      // Get service account data to extract project_id
      final serviceAccountData = await _getServiceAccountData(app.id);
      final projectId = serviceAccountData['project_id'] as String;
      
      // Get OAuth 2.0 access token
      final accessToken = await _getAccessToken(app.id);
      
      // Use FCM HTTP v1 API endpoint
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');
      
      // Build the message payload according to v1 API format
      final message = <String, dynamic>{
        'notification': {
          'title': title,
          'body': body,
          if (imageUrl != null) 'image': imageUrl,
        },
        if (data != null) 'data': data,
      };
      
      // Set target (token, topic, or condition)
      if (topic != null && topic.isNotEmpty) {
        message['topic'] = topic;
      } else if (tokens != null && tokens.isNotEmpty) {
        if (tokens.length == 1) {
          message['token'] = tokens.first;
        } else {
          // For multiple tokens, we need to send multiple requests or use condition
          // For now, send to first token (you might want to implement batch sending)
          message['token'] = tokens.first;
        }
      } else {
        throw Exception('Either topic or tokens must be provided');
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

