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
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
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
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildInfoCard('App', notification.app.name, icon: HeroIcons.devicePhoneMobile),
                                    const SizedBox(height: 8),
                                    _buildInfoCard('Body', notification.body, icon: HeroIcons.documentText),
                                    if (notification.topic != null) ...[
                                      const SizedBox(height: 8),
                                      _buildInfoCard('Topic', notification.topic!, icon: HeroIcons.hashtag),
                                    ],
                                    if (notification.tokens != null && notification.tokens!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _buildInfoCard(
                                        'Recipient',
                                        '${notification.tokens!.length} token(s)',
                                        icon: HeroIcons.user,
                                      ),
                                    ],
                                    if (notification.data != null && notification.data!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  HeroIcon(HeroIcons.codeBracket, size: 18),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Custom Data',
                                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              ...notification.data!.entries.map((entry) => Padding(
                                                padding: const EdgeInsets.only(bottom: 4),
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
                                      ),
                                    ],
                                    if (notification.error != null) ...[
                                      const SizedBox(height: 8),
                                      Card(
                                        color: Theme.of(context).colorScheme.errorContainer,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
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
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      notification.error!,
                                                      style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: () => _deleteNotification(notification).then((deleted) {
                                        if (deleted) {
                                          widget.onDataChanged?.call();
                                        }
                                      }),
                                      icon: const HeroIcon(HeroIcons.trash),
                                      label: const Text('Delete Notification'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.error,
                                        side: BorderSide(color: Theme.of(context).colorScheme.error),
                                      ),
                                    ),
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

  Widget _buildInfoCard(String label, String value, {required HeroIcons icon}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroIcon(icon, size: 18),
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

