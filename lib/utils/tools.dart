import 'dart:convert';

class ErrorUtils {
  /// Parses the error to extract the JSON error string if available.
  /// Returns the JSON string so it can be saved and parsed later for display.
  /// If no JSON is found, returns the original error string.
  static String parseError(dynamic error) {
    final errorString = error.toString();
    
    // Check if error contains JSON response body
    // Format: "Exception: FCM API error: 400 - {...json...}" (multiline)
    // Try to find JSON object starting after "FCM API error: \d+ - "
    final jsonMatch = RegExp(r'FCM API error: \d+ - (.+)$', dotAll: true).firstMatch(errorString);
    if (jsonMatch != null) {
      final jsonString = jsonMatch.group(1);
      if (jsonString != null) {
        try {
          // Try to parse as JSON to validate it
          jsonDecode(jsonString.trim()) as Map<String, dynamic>;
          // Return the JSON string so it can be parsed later for display
          return jsonString.trim();
        } catch (e) {
          // Not valid JSON, continue to other checks
        }
      }
    }
    
    // Alternative: Try to extract JSON object directly from the string
    // Look for opening brace and try to parse from there
    final braceIndex = errorString.indexOf('{');
    if (braceIndex != -1) {
      try {
        final jsonString = errorString.substring(braceIndex);
        jsonDecode(jsonString) as Map<String, dynamic>;
        return jsonString;
      } catch (e) {
        // Not valid JSON, continue
      }
    }
    
    // Check if the error string itself is JSON
    try {
      jsonDecode(errorString) as Map<String, dynamic>;
      return errorString;
    } catch (e) {
      // Not JSON, return original error string
    }
    
    return errorString;
  }

  /// Extracts error code and message from an error.
  /// Returns a map with 'code' and 'message' keys if found, null otherwise.
  static Map<String, String>? extractErrorCodeAndMessage(dynamic error) {
    final errorString = error.toString();
    
    try {
      // Check if error contains JSON response body
      final jsonMatch = RegExp(r'FCM API error: \d+ - (.+)$', dotAll: true).firstMatch(errorString);
      String? jsonString;
      
      if (jsonMatch != null) {
        jsonString = jsonMatch.group(1)?.trim();
      } else {
        // Alternative: Try to extract JSON object directly
        final braceIndex = errorString.indexOf('{');
        if (braceIndex != -1) {
          jsonString = errorString.substring(braceIndex);
        } else {
          // Check if the error string itself is JSON
          jsonString = errorString;
        }
      }
      
      if (jsonString != null) {
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        final errorObj = jsonData['error'] as Map<String, dynamic>?;
        final code = errorObj?['code']?.toString() ?? jsonData['code']?.toString();
        final message = errorObj?['message']?.toString() ?? jsonData['message']?.toString();
        
        if (code != null || message != null) {
          return {
            if (code != null) 'code': code,
            if (message != null) 'message': message,
          };
        }
      }
    } catch (e) {
      // Not JSON or parsing failed
    }
    
    return null;
  }
}

/// Formats a DateTime to dd/mm/yyyy hh:mm format.
String formatDate(DateTime date) {
  final localDate = date.toLocal();
  final day = localDate.day.toString().padLeft(2, '0');
  final month = localDate.month.toString().padLeft(2, '0');
  final year = localDate.year.toString();
  final hour = localDate.hour.toString().padLeft(2, '0');
  final minute = localDate.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
