import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/app_model.dart';
import '../models/notification_model.dart';
import '../models/topic_model.dart';
import '../models/user_model.dart';
import '../services/app_storage_service.dart';
import '../services/notification_storage_service.dart';
import '../services/topic_storage_service.dart';
import '../services/user_storage_service.dart';
import '../services/fcm_service.dart';

class CreateNotificationScreen extends StatefulWidget {
  const CreateNotificationScreen({super.key});

  @override
  State<CreateNotificationScreen> createState() => _CreateNotificationScreenState();
}

class _CreateNotificationScreenState extends State<CreateNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _dataKeyController = TextEditingController();
  final _dataValueController = TextEditingController();

  final _appStorage = AppStorageService();
  final _notificationStorage = NotificationStorageService();
  final _topicStorage = TopicStorageService();
  final _userStorage = UserStorageService();
  final _fcmService = FCMService();

  List<AppModel> _apps = [];
  AppModel? _selectedApp;
  List<TopicModel> _topics = [];
  List<UserModel> _users = [];
  TopicModel? _selectedTopic;
  final Set<String> _selectedUserIds = {};
  bool _isLoading = false;
  final Map<String, String> _customData = {};

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await _appStorage.getApps();
    setState(() {
      _apps = apps;
      if (apps.isNotEmpty && _selectedApp == null) {
        _selectedApp = apps.first;
        _loadAppData(apps.first);
      }
    });
  }

  Future<void> _loadAppData(AppModel app) async {
    final topics = await _topicStorage.getTopics(app.id);
    final users = await _userStorage.getUsers(app.id);
    setState(() {
      _topics = topics;
      _users = users;
      _selectedTopic = null;
      _selectedUserIds.clear();
    });
  }

  void _addCustomData() {
    final key = _dataKeyController.text.trim();
    final value = _dataValueController.text.trim();
    if (key.isNotEmpty && value.isNotEmpty) {
      setState(() {
        _customData[key] = value;
        _dataKeyController.clear();
        _dataValueController.clear();
      });
    }
  }

  void _removeCustomData(String key) {
    setState(() {
      _customData.remove(key);
    });
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an app')),
      );
      return;
    }

    if (_selectedTopic == null && _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select either a topic or at least one user')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        appId: _selectedApp!.id,
        appName: _selectedApp!.name,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        data: _customData.isEmpty ? null : _customData,
        topic: _selectedTopic?.name,
        tokens: _selectedUserIds.isEmpty
            ? null
            : _users
                .where((u) => _selectedUserIds.contains(u.id))
                .map((u) => u.notificationToken)
                .toList(),
        createdAt: DateTime.now(),
      );

      final success = await _fcmService.sendNotification(
        app: _selectedApp!,
        title: notification.title,
        body: notification.body,
        imageUrl: null,
        data: notification.data,
        topic: notification.topic,
        tokens: notification.tokens,
      );

      final savedNotification = notification.copyWith(
        sent: success,
        error: success ? null : 'Failed to send notification',
      );

      await _notificationStorage.saveNotification(savedNotification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Notification sent successfully' : 'Failed to send notification'),
            backgroundColor: success ? Colors.green : Theme.of(context).colorScheme.error,
          ),
        );

        if (success) {
          _titleController.clear();
          _bodyController.clear();
          setState(() {
            _selectedTopic = null;
            _selectedUserIds.clear();
            _customData.clear();
          });
        }
      }
    } catch (e) {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        appId: _selectedApp!.id,
        appName: _selectedApp!.name,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        data: _customData.isEmpty ? null : _customData,
        topic: _selectedTopic?.name,
        tokens: _selectedUserIds.isEmpty
            ? null
            : _users
                .where((u) => _selectedUserIds.contains(u.id))
                .map((u) => u.notificationToken)
                .toList(),
        createdAt: DateTime.now(),
        sent: false,
        error: e.toString(),
      );

      await _notificationStorage.saveNotification(notification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _dataKeyController.dispose();
    _dataValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Push Notification',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (_apps.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Please add an app first before creating notifications',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<AppModel>(
                        initialValue: _selectedApp,
                        decoration: const InputDecoration(
                          labelText: 'Choose an app',
                          border: OutlineInputBorder(),
                        ),
                        items: _apps.map((app) => DropdownMenuItem<AppModel>(
                          value: app,
                          child: Text(app.name),
                        )).toList(),
                        onChanged: (app) {
                          if (app != null) {
                            _loadAppData(app);
                            setState(() {
                              _selectedApp = app;
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      enabled: _selectedApp != null,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Notification title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bodyController,
                      enabled: _selectedApp != null,
                      decoration: const InputDecoration(
                        labelText: 'Body',
                        hintText: 'Notification body text',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter body';
                        }
                        return null;
                      },
                    ),
                    if (_selectedApp != null) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TopicModel?>(
                        initialValue: _selectedTopic,
                        decoration: const InputDecoration(
                          labelText: 'Select Topic (Optional)',
                          border: OutlineInputBorder(),
                          helperText: 'Select a topic or select users below',
                        ),
                        items: [
                          const DropdownMenuItem<TopicModel?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ..._topics.map((topic) => DropdownMenuItem<TopicModel?>(
                            value: topic,
                            child: Text(topic.name),
                          )),
                        ],
                        onChanged: (topic) {
                          setState(() {
                            _selectedTopic = topic;
                            if (topic != null) {
                              _selectedUserIds.clear();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_users.isNotEmpty) ...[
                        Text(
                          'Select Users (Optional)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return CheckboxListTile(
                                title: Text(user.name),
                                subtitle: Text(
                                  user.notificationToken,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                value: _selectedUserIds.contains(user.id),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedUserIds.add(user.id);
                                      _selectedTopic = null;
                                    } else {
                                      _selectedUserIds.remove(user.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ] else if (_selectedApp != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'No users added for this app. Add users in the app detail screen.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Custom Data',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dataKeyController,
                            enabled: _selectedApp != null,
                            decoration: const InputDecoration(
                              labelText: 'Key',
                              hintText: 'Key',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _dataValueController,
                            enabled: _selectedApp != null,
                            decoration: const InputDecoration(
                              labelText: 'Value',
                              hintText: 'Value',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _selectedApp != null ? _addCustomData : null,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    if (_customData.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ..._customData.entries.map((entry) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(entry.key),
                              subtitle: Text(entry.value),
                              trailing: IconButton(
                                icon: const HeroIcon(HeroIcons.xMark),
                                onPressed: () => _removeCustomData(entry.key),
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_selectedApp != null && !_isLoading) ? _sendNotification : null,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Notification'),
            ),
          ],
        ),
      ),
    );
  }
}

extension NotificationModelExtension on NotificationModel {
  NotificationModel copyWith({
    String? id,
    String? appId,
    String? appName,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? topic,
    List<String>? tokens,
    DateTime? createdAt,
    bool? sent,
    String? error,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      appName: appName ?? this.appName,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      topic: topic ?? this.topic,
      tokens: tokens ?? this.tokens,
      createdAt: createdAt ?? this.createdAt,
      sent: sent ?? this.sent,
      error: error ?? this.error,
    );
  }
}

