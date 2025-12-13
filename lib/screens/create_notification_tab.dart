import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/app_model.dart';
import '../models/notification_model.dart';
import '../services/app_storage_service.dart';
import '../services/notification_storage_service.dart';
import '../services/fcm_service.dart';

class CreateNotificationTab extends StatefulWidget {
  const CreateNotificationTab({super.key});

  @override
  State<CreateNotificationTab> createState() => _CreateNotificationTabState();
}

class _CreateNotificationTabState extends State<CreateNotificationTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _topicController = TextEditingController();
  final _tokensController = TextEditingController();
  final _dataKeyController = TextEditingController();
  final _dataValueController = TextEditingController();

  final _appStorage = AppStorageService();
  final _notificationStorage = NotificationStorageService();
  final _fcmService = FCMService();

  List<AppModel> _apps = [];
  AppModel? _selectedApp;
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
      }
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
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('Please select an app'),
        ),
      );
      return;
    }

    if (_topicController.text.trim().isEmpty && 
        _tokensController.text.trim().isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('Please provide either topic or tokens'),
        ),
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
        imageUrl: _imageUrlController.text.trim().isEmpty 
            ? null 
            : _imageUrlController.text.trim(),
        data: _customData.isEmpty ? null : _customData,
        topic: _topicController.text.trim().isEmpty 
            ? null 
            : _topicController.text.trim(),
        tokens: _tokensController.text.trim().isEmpty
            ? null
            : _tokensController.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList(),
        createdAt: DateTime.now(),
      );

      final success = await _fcmService.sendNotification(
        app: _selectedApp!,
        title: notification.title,
        body: notification.body,
        imageUrl: notification.imageUrl,
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
        ShadToaster.of(context).show(
          success ? ShadToast(
            description: Text('Notification sent successfully'),
          ) : ShadToast.destructive(
            description: Text('Failed to send notification'),
          ),
        );

        if (success) {
          _titleController.clear();
          _bodyController.clear();
          _imageUrlController.clear();
          _topicController.clear();
          _tokensController.clear();
          _customData.clear();
        }
      }
    } catch (e) {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        appId: _selectedApp!.id,
        appName: _selectedApp!.name,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty 
            ? null 
            : _imageUrlController.text.trim(),
        data: _customData.isEmpty ? null : _customData,
        topic: _topicController.text.trim().isEmpty 
            ? null 
            : _topicController.text.trim(),
        tokens: _tokensController.text.trim().isEmpty
            ? null
            : _tokensController.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList(),
        createdAt: DateTime.now(),
        sent: false,
        error: e.toString(),
      );

      await _notificationStorage.saveNotification(notification);

      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('Error: $e'),
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
    _imageUrlController.dispose();
    _topicController.dispose();
    _tokensController.dispose();
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
            ShadCard(
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
                      ShadAlert.destructive(
                        description: const Text(
                          'Please add an app first before creating notifications',
                        ),
                      )
                    else
                      ShadSelectFormField<AppModel>(
                        initialValue: _selectedApp,
                        placeholder: const Text('Choose an app'),
                        options: _apps.map((app) => ShadOption(value: app, child: Text(app.name))).toList(),
                        onChanged: (app) {
                          setState(() {
                            _selectedApp = app;
                          });
                        }, 
                        selectedOptionBuilder: (BuildContext context, AppModel value) { return Text(value.name); },
                      ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      controller: _titleController,
                      placeholder: const Text('Notification title'),
                      label: const Text('Title'),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ShadTextareaFormField(
                      controller: _bodyController,
                      placeholder: const Text('Notification body text'),
                      label: const Text('Body'),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter body';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      controller: _imageUrlController,
                      placeholder: const Text('https://example.com/image.jpg'),
                      label: const Text('Image URL (Optional)'),
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      controller: _topicController,
                      placeholder: const Text('news'),
                      label: const Text('Topic (Optional)'),
                      description: const Text('Send to a topic or provide tokens below'),
                    ),
                    const SizedBox(height: 16),
                    ShadTextareaFormField(
                      controller: _tokensController,
                      placeholder: const Text('token1, token2, token3'),
                      label: const Text('Device Tokens (Optional)'),
                      description: const Text('Comma-separated FCM device tokens'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ShadCard(
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
                          child: ShadInputFormField(
                            controller: _dataKeyController,
                            placeholder: const Text('Key'),
                            label: const Text('Key'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ShadInputFormField(
                            controller: _dataValueController,
                            placeholder: const Text('Value'),
                            label: const Text('Value'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ShadButton(
                          onPressed: _addCustomData,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    if (_customData.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ..._customData.entries.map((entry) => ShadCard(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(entry.key),
                              subtitle: Text(entry.value),
                              trailing: ShadIconButton(
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
            ShadButton(
              onPressed: _isLoading ? null : _sendNotification,
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
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      topic: topic ?? this.topic,
      tokens: tokens ?? this.tokens,
      createdAt: createdAt ?? this.createdAt,
      sent: sent ?? this.sent,
      error: error ?? this.error,
    );
  }
}

