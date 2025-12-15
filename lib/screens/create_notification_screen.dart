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
  final void Function(VoidCallback)? onRefreshCallback;
  final VoidCallback? onDataChanged;

  const CreateNotificationScreen({
    super.key,
    this.onRefreshCallback,
    this.onDataChanged,
  });

  @override
  State<CreateNotificationScreen> createState() => _CreateNotificationScreenState();
}

class _CreateNotificationScreenState extends State<CreateNotificationScreen> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

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
  UserModel? _selectedUser;
  bool _isLoading = false;
  final Map<String, String> _customData = {};
  bool _useTopics = true; // true for topics, false for users

  @override
  void initState() {
    super.initState();
    widget.onRefreshCallback?.call(_refresh);
    _loadApps();
  }

  void _refresh() {
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await _appStorage.getApps();
    setState(() {
      _apps = apps;
      if (apps.isNotEmpty) {
        // If we have a selected app, find it in the new list by ID
        if (_selectedApp != null) {
          final matchingApp = apps.firstWhere(
            (app) => app.id == _selectedApp!.id,
            orElse: () => apps.first,
          );
          _selectedApp = matchingApp;
          _loadAppData(matchingApp);
        } else {
          _selectedApp = apps.first;
          _loadAppData(apps.first);
        }
      } else {
        _selectedApp = null;
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
      _selectedUser = null;
    });
  }

  Future<void> _showAddCustomDataDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _AddCustomDataDialog(),
    );

    if (result != null && result.containsKey('key') && result.containsKey('value')) {
      final key = result['key']!;
      final value = result['value']!;
      
      if (key.isNotEmpty && value.isNotEmpty) {
        setState(() {
          _customData[key] = value;
        });
      }
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

    setState(() {
      _isLoading = true;
    });

    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        app: _selectedApp!,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        data: _customData.isEmpty ? null : _customData,
        topic: _selectedTopic?.name,
        tokens: _selectedUser == null ? null : [_selectedUser!.notificationToken],
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
            if (_useTopics) {
              _selectedTopic = null;
            } else {
              _selectedUser = null;
            }
            _customData.clear();
          });
          widget.onDataChanged?.call();
        }
      }
    } catch (e) {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        app: _selectedApp!,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        data: _customData.isEmpty ? null : _customData,
        topic: _selectedTopic?.name,
        tokens: _selectedUser == null ? null : [_selectedUser!.notificationToken],
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
        widget.onDataChanged?.call();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      onChanged: _apps.isNotEmpty ? (app) {
                        if (app != null) {
                          _loadAppData(app);
                          setState(() {
                            _selectedApp = app;
                          });
                        }
                      } : null,
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: ToggleButtons(
                            isSelected: [_useTopics, !_useTopics],
                            constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 64) / 2),
                            onPressed: (index) {
                              setState(() {
                                _useTopics = index == 0;
                                // Clear the other selection when switching
                                if (_useTopics) {
                                  _selectedUser = null;
                                } else {
                                  _selectedTopic = null;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HeroIcon(HeroIcons.hashtag, size: 16),
                                    SizedBox(width: 8),
                                    Text('Topics'),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HeroIcon(HeroIcons.user, size: 16),
                                    SizedBox(width: 8),
                                    Text('Users'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_useTopics)
                      DropdownButtonFormField<TopicModel?>(
                        initialValue: _selectedTopic,
                        decoration: const InputDecoration(
                          labelText: 'Select Topic',
                          border: OutlineInputBorder(),
                        ),
                        items: _topics.map((topic) => DropdownMenuItem<TopicModel?>(
                          value: topic,
                          child: Text(topic.name),
                        )).toList(),
                        onChanged: _topics.isNotEmpty ? (topic) {
                          setState(() {
                            _selectedTopic = topic;
                          });
                        } : null,
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a topic';
                          }
                          return null;
                        },
                      )
                    else
                      DropdownButtonFormField<UserModel?>(
                        initialValue: _selectedUser,
                        decoration: const InputDecoration(
                          labelText: 'Select User',
                          border: OutlineInputBorder(),
                        ),
                        items: _users.map((user) => DropdownMenuItem<UserModel?>(
                          value: user,
                          child: Text(user.name),
                        )).toList(),
                        onChanged: _users.isNotEmpty ? (user) {
                          setState(() {
                            _selectedUser = user;
                          });
                        } : null,
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a user';
                          }
                          return null;
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Custom Data',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        OutlinedButton.icon(
                          onPressed: _selectedApp != null ? _showAddCustomDataDialog : null,
                          icon: const HeroIcon(HeroIcons.plus),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    if (_customData.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._customData.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                title: Text(entry.key),
                                subtitle: Text(entry.value),
                                trailing: IconButton(
                                  icon: const HeroIcon(HeroIcons.xMark),
                                  onPressed: () => _removeCustomData(entry.key),
                                ),
                              ),
                            ),
                      )),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: (_selectedApp != null && 
                         !_isLoading && 
                         ((_useTopics && _selectedTopic != null) || (!_useTopics && _selectedUser != null))) 
                  ? _sendNotification 
                  : null,
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
      app: app,
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

class _AddCustomDataDialog extends StatefulWidget {
  const _AddCustomDataDialog();

  @override
  State<_AddCustomDataDialog> createState() => _AddCustomDataDialogState();
}

class _AddCustomDataDialogState extends State<_AddCustomDataDialog> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Data'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _keyController,
                decoration: const InputDecoration(
                  labelText: 'Key',
                  hintText: 'Enter key',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a key';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Value',
                  hintText: 'Enter value',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a value';
                  }
                  return null;
                },
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'key': _keyController.text.trim(),
                'value': _valueController.text.trim(),
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}


