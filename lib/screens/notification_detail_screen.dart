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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: notification.sent
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HeroIcon(
                              notification.sent ? HeroIcons.checkCircle : HeroIcons.xCircle,
                              style: HeroIconStyle.solid,
                              color: notification.sent ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              notification.sent ? 'Sent' : 'Failed',
                              style: TextStyle(
                                color: notification.sent ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (notification.error != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorDisplay(context, notification.error!),
                  ],
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

  Widget _buildErrorDisplay(BuildContext context, String errorString) {
    Map<String, dynamic>? errorJson;
    String? errorCode;
    String? errorMessage;

    // Try to parse as JSON
    try {
      errorJson = jsonDecode(errorString) as Map<String, dynamic>;
      errorCode = errorJson['code']?.toString() ?? errorJson['error']?['code']?.toString();
      errorMessage = errorJson['message']?.toString() ?? errorJson['error']?['message']?.toString();
    } catch (e) {
      // Not JSON, use the string as-is
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroIcon(
            HeroIcons.exclamationCircle,
            color: Theme.of(context).colorScheme.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                if (errorCode != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          errorCode,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                if (errorMessage != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    errorString,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
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
      final updatedNotification = notification.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        sent: false,
        error: e.toString(),
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
}
