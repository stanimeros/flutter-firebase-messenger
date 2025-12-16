import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/notification_model.dart';
import '../models/app_model.dart';
import '../services/notification_storage_service.dart';
import 'notification_detail_screen.dart';
import '../utils/tools.dart';

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
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
                      const SizedBox(height: 12),
                      Text(
                        'No notifications sent yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            child: const HeroIcon(
                              HeroIcons.trash,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          final deleted = await _deleteNotification(notification);
                          if (deleted) {
                            widget.onDataChanged?.call();
                          }
                          return deleted;
                        },
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: _buildAppImage(notification.app),
                            title: Text(notification.nickname),
                            subtitle: Text(
                              formatDate(notification.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: _buildStatusIcon(notification.sent),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NotificationDetailScreen(
                                    notification: notification,
                                    onDataChanged: () {
                                      _loadNotifications();
                                      widget.onDataChanged?.call();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
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

