import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'secure_storage_service.dart';

class GeminiService {
  final _secureStorage = SecureStorageService();
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  static const String _generativeLanguageScope = 'https://www.googleapis.com/auth/generative-language';

  /// Get access token from service account credentials
  Future<String> _getAccessToken(String appId) async {
    try {
      // Get service account credentials from secure storage
      final serviceAccount = await _secureStorage.getAppCredentials(appId);
      
      if (serviceAccount == null) {
        throw Exception('Service account credentials not found. Please update the app and select the JSON file again.');
      }
      
      // Validate the credentials
      if (serviceAccount.isEmpty) {
        throw Exception('Invalid service account JSON. Missing required fields: project_id, client_email, or private_key.');
      }
      
      // Create service account credentials from JSON
      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      
      // Obtain authenticated client using clientViaServiceAccount
      final client = await clientViaServiceAccount(
        credentials,
        [_generativeLanguageScope],
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

  /// Check if service account credentials are available for the app
  Future<bool> hasCredentials(String appId) async {
    final credentials = await _secureStorage.getAppCredentials(appId);
    return credentials != null && credentials.isNotEmpty;
  }

  /// Refine text using Gemini API
  /// [appId] is the ID of the app to use for service account credentials
  /// [originalText] is the text to refine
  /// [customPrompt] is the custom prompt to use (will include originalText automatically)
  Future<String?> refineText(String appId, String originalText, String customPrompt) async {
    final prompt = '$customPrompt\n\n$originalText';

    try {
      // Get OAuth 2.0 access token from service account
      final accessToken = await _getAccessToken(appId);

      // Use the Generative Language API with access token
      final url = Uri.parse(_geminiApiUrl);
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            return text?.trim();
          }
        }
        throw Exception('No response from Gemini API');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final error = errorData?['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Unknown error';
        throw Exception('Gemini API error: ${response.statusCode} - $message');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to refine text: $e');
    }
  }
}
