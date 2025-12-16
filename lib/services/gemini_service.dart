import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Get the API key for the current platform from .env
  String? _getApiKey() {
    final isIOS = Platform.isIOS;
    return isIOS 
        ? dotenv.env['GEMINI_IOS_API_KEY']
        : dotenv.env['GEMINI_ANDROID_API_KEY'];
  }

  String? _getBundleId() {
    final isIOS = Platform.isIOS;
    return isIOS 
        ? dotenv.env['IOS_BUNDLE_ID']
        : dotenv.env['ANDROID_PACKAGE_NAME'];
  }

  /// Check if API key is set for the current platform
  bool hasApiKey() {
    final apiKey = _getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Refine text using Gemini API
  /// [originalText] is the text to refine
  /// [customPrompt] is the custom prompt to use (will include originalText automatically)
  Future<String?> refineText(String originalText, String customPrompt) async {
    final apiKey = _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key not set in .env file. Please configure GEMINI_IOS_API_KEY or GEMINI_ANDROID_API_KEY.');
    }

    final prompt = '$customPrompt\n\n$originalText';

    try {
      final url = Uri.parse('$_geminiApiUrl?key=$apiKey');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (Platform.isIOS) 'X-Ios-Bundle-Identifier': _getBundleId() ?? '',
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
