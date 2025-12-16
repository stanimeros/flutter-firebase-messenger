import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/notification_model.dart';
import '../services/notification_storage_service.dart';
import '../services/fcm_service.dart';
import 'create_notification_screen.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onDataChanged;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
    this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(notification.nickname ?? 'Notification Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(
              context,
              'App',
              notification.app.name,
              icon: HeroIcons.cube,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              'Title',
              notification.title,
              icon: HeroIcons.documentText,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              'Body',
              notification.body,
              icon: HeroIcons.chatBubbleLeftRight,
            ),
            if (notification.nickname != null && notification.nickname!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                'Nickname',
                notification.nickname!,
                icon: HeroIcons.tag,
              ),
            ],
            if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                'Image URL',
                notification.imageUrl!,
                icon: HeroIcons.photo,
              ),
            ],
            if (notification.topic != null) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                'Topic',
                notification.topic!,
                icon: HeroIcons.hashtag,
              ),
            ],
            if (notification.condition != null) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                'Condition',
                notification.condition!,
                icon: HeroIcons.funnel,
              ),
            ],
            if (notification.tokens != null && notification.tokens!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                'Recipient',
                '${notification.tokens!.length} token(s)',
                icon: HeroIcons.user,
              ),
            ],
            if (notification.data != null && notification.data!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HeroIcon(HeroIcons.codeBracket, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Custom Data',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...notification.data!.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                HeroIcon(HeroIcons.clock, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Sent At',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notification.createdAt.toLocal().toString().split('.')[0],
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Error code or 200 in top right
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: notification.sent
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusCode(notification),
                          style: TextStyle(
                            color: notification.sent ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: notification.sent
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeroIcon(
                          notification.sent ? HeroIcons.checkCircle : HeroIcons.xCircle,
                          style: HeroIconStyle.solid,
                          color: notification.sent ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _getStatusMessage(notification),
                            style: TextStyle(
                              color: notification.sent ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: null,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _duplicateNotification(context),
                    icon: const HeroIcon(HeroIcons.documentDuplicate),
                    label: const Text('Duplicate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: notification.sent ? null : () => _resendNotification(context),
                    icon: const HeroIcon(HeroIcons.paperAirplane),
                    label: const Text('Resend'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusCode(NotificationModel notification) {
    if (notification.sent) {
      return '200';
    }
    
    if (notification.error != null) {
      try {
        final errorJson = jsonDecode(notification.error!) as Map<String, dynamic>;
        final errorCode = errorJson['error']?['code']?.toString() ?? errorJson['code']?.toString();
        if (errorCode != null) {
          return errorCode;
        }
      } catch (e) {
        // Not JSON, return default
      }
    }
    
    return 'Error';
  }

  String _getStatusMessage(NotificationModel notification) {
    if (notification.sent) {
      return 'Sent';
    }
    
    if (notification.error != null) {
      try {
        final errorJson = jsonDecode(notification.error!) as Map<String, dynamic>;
        final errorMessage = errorJson['error']?['message']?.toString() ?? errorJson['message']?.toString();
        if (errorMessage != null) {
          return errorMessage;
        }
      } catch (e) {
        // Not JSON, return default
      }
    }
    
    return 'Failed';
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, {required HeroIcons icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroIcon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _duplicateNotification(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNotificationScreen(
          initialNotification: notification,
          onDataChanged: onDataChanged,
        ),
      ),
    );
  }

  Future<void> _resendNotification(BuildContext context) async {
    final fcmService = FCMService();
    final notificationStorage = NotificationStorageService();

    try {
      final success = await fcmService.sendNotification(
        app: notification.app,
        title: notification.title,
        body: notification.body,
        imageUrl: notification.imageUrl,
        data: notification.data,
        topic: notification.topic,
        condition: notification.condition,
        tokens: notification.tokens,
      );

      final updatedNotification = notification.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        sent: success,
        error: success ? null : 'Failed to send notification',
      );

      await notificationStorage.saveNotification(updatedNotification);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Notification resent successfully' : 'Failed to resend notification'),
            backgroundColor: success ? Colors.green : Theme.of(context).colorScheme.error,
          ),
        );
        onDataChanged?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      // Parse error to extract JSON error if available
      final errorString = _parseError(e);
      
      final updatedNotification = notification.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        sent: false,
        error: errorString,
      );

      await notificationStorage.saveNotification(updatedNotification);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        onDataChanged?.call();
      }
    }
  }

  String? _parseError(dynamic error) {
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
}
