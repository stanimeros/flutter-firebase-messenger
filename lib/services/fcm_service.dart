import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_model.dart';

class FCMService {

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
      final serverKey = app.serverKey;
      if (serverKey == null || serverKey.isEmpty) {
        throw Exception('Server key not configured for this app');
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

