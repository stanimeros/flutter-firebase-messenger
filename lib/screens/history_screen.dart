import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/notification_model.dart';
import '../models/app_model.dart';
import '../services/notification_storage_service.dart';

class HistoryScreen extends StatefulWidget {
  final void Function(VoidCallback)? onRefreshCallback;
  final VoidCallback? onDataChanged;

  const HistoryScreen({
    super.key,
    this.onRefreshCallback,
    this.onDataChanged,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with AutomaticKeepAliveClientMixin {
  final _notificationStorage = NotificationStorageService();
  List<NotificationModel> _notifications = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.onRefreshCallback?.call(_loadNotifications);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await _notificationStorage.getNotifications();
    setState(() {
      _notifications = notifications;
    });
  }

  Future<bool> _deleteNotification(NotificationModel notification) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
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
      return true;
    }
    return false;
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all notification history?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
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
    super.build(context);
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
                OutlinedButton(
                  onPressed: _clearHistory,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      HeroIcon(HeroIcons.trash),
                      SizedBox(width: 8),
                      Text('Clear All'),
                    ],
                  ),
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
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const HeroIcon(
                            HeroIcons.trash,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await _deleteNotification(notification);
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            leading: _buildAppImage(notification.app),
                            title: Text(notification.title),
                            subtitle: Text(
                              notification.createdAt.toLocal().toString().split('.')[0],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: _buildStatusIcon(notification.sent),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow('App', notification.app.name),
                                    _buildInfoRow('Body', notification.body),
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

  Widget _buildAppImage(AppModel app) {
    if (app.imageData != null && app.imageData!.isNotEmpty) {
      try {
        final imageBytes = base64Decode(app.imageData!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            imageBytes,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar(app);
            },
          ),
        );
      } catch (e) {
        return _buildDefaultAvatar(app);
      }
    }
    return _buildDefaultAvatar(app);
  }

  Widget _buildDefaultAvatar(AppModel app) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          app.name.isNotEmpty ? app.name[0].toUpperCase() : 'A',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool sent) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: sent
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: HeroIcon(
        sent ? HeroIcons.checkCircle : HeroIcons.xCircle,
        style: HeroIconStyle.solid,
        color: sent ? Colors.green : Colors.red,
        size: 24,
      ),
    );
  }
}

