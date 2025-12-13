import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/notification_storage_service.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final _notificationStorage = NotificationStorageService();
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await _notificationStorage.getNotifications();
    setState(() {
      _notifications = notifications;
    });
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _notificationStorage.deleteNotification(notification.id);
      _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all notification history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _notificationStorage.clearHistory();
      _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_notifications.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notification History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: _clearHistory,
                  icon: const HeroIcon(HeroIcons.trash),
                  label: const Text('Clear All'),
                ),
              ],
            ),
          ),
        Expanded(
          child: _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HeroIcon(
                        HeroIcons.inbox,
                        size: 64,
                        style: HeroIconStyle.outline,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications sent yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: notification.sent
                                ? Colors.green
                                : Colors.red,
                            child: HeroIcon(
                              notification.sent
                                  ? HeroIcons.checkCircle
                                  : HeroIcons.xCircle,
                              style: HeroIconStyle.solid,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(notification.title),
                          subtitle: Text(
                            DateFormat('MMM dd, yyyy HH:mm')
                                .format(notification.createdAt),
                          ),
                          trailing: IconButton(
                            icon: const HeroIcon(HeroIcons.trash),
                            onPressed: () => _deleteNotification(notification),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('App', notification.appName),
                                  _buildInfoRow('Body', notification.body),
                                  if (notification.imageUrl != null)
                                    _buildInfoRow(
                                        'Image URL', notification.imageUrl!),
                                  if (notification.topic != null)
                                    _buildInfoRow('Topic', notification.topic!),
                                  if (notification.tokens != null &&
                                      notification.tokens!.isNotEmpty)
                                    _buildInfoRow(
                                        'Tokens',
                                        '${notification.tokens!.length} token(s)'),
                                  if (notification.data != null &&
                                      notification.data!.isNotEmpty)
                                    ...notification.data!.entries.map((entry) =>
                                        _buildInfoRow(
                                            'Data: ${entry.key}', entry.value.toString())),
                                  _buildInfoRow(
                                      'Status',
                                      notification.sent ? 'Sent' : 'Failed'),
                                  if (notification.error != null)
                                    _buildInfoRow(
                                        'Error', notification.error!,
                                        isError: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isError ? Colors.red : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isError ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }
}

