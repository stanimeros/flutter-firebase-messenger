import 'package:googleapis_auth/auth_io.dart';
import 'secure_storage_service.dart';

class TokenService {
  final _secureStorage = SecureStorageService();
  
  static const String _generativeLanguageScope = 'https://www.googleapis.com/auth/generative-language';
  static const String _fcmScope = 'https://www.googleapis.com/auth/firebase.messaging';

  /// Generate access token with specified scopes
  Future<String> getAccessToken(String appId, List<String> scopes) async {
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
        scopes,
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

  /// Generate access token for Gemini service
  Future<String> getGeminiAccessToken(String appId) async {
    return getAccessToken(appId, [_generativeLanguageScope]);
  }

  /// Generate access token for FCM messaging service
  Future<String> getFcmAccessToken(String appId) async {
    return getAccessToken(appId, [_fcmScope]);
  }

  /// Generate both tokens at once for better performance
  Future<Map<String, String>> getBothTokens(String appId) async {
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
      
      // Generate both tokens in parallel for better performance
      final results = await Future.wait([
        _getTokenForScope(credentials, [_generativeLanguageScope]),
        _getTokenForScope(credentials, [_fcmScope]),
      ]);
      
      return {
        'gemini': results[0],
        'fcm': results[1],
      };
    } catch (e) {
      throw Exception('Failed to generate access tokens: $e');
    }
  }

  Future<String> _getTokenForScope(ServiceAccountCredentials credentials, List<String> scopes) async {
    final client = await clientViaServiceAccount(credentials, scopes);
    final accessToken = client.credentials.accessToken.data;
    client.close();
    
    if (accessToken.isEmpty) {
      throw Exception('Failed to obtain access token from service account.');
    }
    
    return accessToken;
  }
}
