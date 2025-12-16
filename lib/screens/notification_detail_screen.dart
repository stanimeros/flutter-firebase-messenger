import 'package:fire_message/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:action_slider/action_slider.dart';
import '../models/notification_model.dart';
import '../services/notification_storage_service.dart';
import '../services/fcm_service.dart';
import 'create_notification_screen.dart';
import '../widgets/custom_app_theme.dart';
import '../utils/tools.dart';

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
        title: Text(notification.nickname),
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
            if (notification.nickname.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                'Nickname',
                notification.nickname,
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
            if (notification.token != null && notification.token!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                'Recipient',
                notification.token!,
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
                    onPressed: notification.sent ? null : () => _showResendConfirmation(context),
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
    return notification.resultCode ?? (notification.sent ? '200' : 'Error');
  }

  String _getStatusMessage(NotificationModel notification) {
    return notification.resultMessage ?? (notification.sent ? 'Sent' : 'Failed');
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
        builder: (context) => Scaffold(
          appBar: CustomAppBar(
            title: Text('Duplicate Notification'),
          ),
          body: CreateNotificationScreen(
            initialNotification: notification,
            onDataChanged: onDataChanged,
          ),
        ),
      ),
    );
  }

  void _showResendConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resend Notification',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const HeroIcon(HeroIcons.xMark),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to resend this notification?',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ActionSlider.standard(
              width: double.infinity,
              height: 56,
              backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
              toggleColor: CustomAppTheme.primaryCyan,
              action: (controller) async {
                controller.loading();
                await _resendNotification(context);
                if (context.mounted) {
                  controller.success();
                  Navigator.pop(context); // Close bottom sheet
                  controller.reset();
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Slide to Resend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
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
        token: notification.token,
      );

      final updatedNotification = notification.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        sent: success,
        resultCode: success ? '200' : null,
        resultMessage: success ? 'Notification resent successfully' : null,
      );

      await notificationStorage.saveNotification(updatedNotification);

      if (context.mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Notification resent successfully' : 'Failed to resend notification'),
              backgroundColor: success ? Colors.green : Theme.of(context).colorScheme.error,
            ),
          );
          onDataChanged?.call();
        }
      }
    } catch (e) {
      // Parse error to extract code and message
      final errorData = ErrorUtils.extractErrorCodeAndMessage(e);
      
      final updatedNotification = notification.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        sent: false,
        resultCode: errorData?['code'],
        resultMessage: errorData?['message'],
      );

      await notificationStorage.saveNotification(updatedNotification);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updatedNotification.resultMessage ?? 'Error occurred'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        onDataChanged?.call();
      }
    }
  }

}
