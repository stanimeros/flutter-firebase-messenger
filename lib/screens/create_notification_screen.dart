import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:action_slider/action_slider.dart';
import '../models/app_model.dart';
import '../models/notification_model.dart';
import '../models/topic_model.dart';
import '../models/device_model.dart';
import '../models/condition_model.dart';
import '../services/app_storage_service.dart';
import '../services/notification_storage_service.dart';
import '../services/fcm_service.dart';

class CreateNotificationScreen extends StatefulWidget {
  final void Function(VoidCallback)? onRefreshCallback;
  final VoidCallback? onDataChanged;
  final NotificationModel? initialNotification;

  const CreateNotificationScreen({
    super.key,
    this.onRefreshCallback,
    this.onDataChanged,
    this.initialNotification,
  });

  @override
  State<CreateNotificationScreen> createState() => _CreateNotificationScreenState();
}

class _CreateNotificationScreenState extends State<CreateNotificationScreen> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  final _appStorage = AppStorageService();
  final _notificationStorage = NotificationStorageService();
  final _fcmService = FCMService();

  List<AppModel> _apps = [];
  AppModel? _selectedApp;
  List<TopicModel> _topics = [];
  List<DeviceModel> _devices = [];
  List<ConditionModel> _conditions = [];
  
  // Selected target (one of: device, topic, or condition)
  DeviceModel? _selectedDevice;
  TopicModel? _selectedTopic;
  ConditionModel? _selectedCondition;
  
  final Map<String, String> _customData = {};

  @override
  void initState() {
    super.initState();
    widget.onRefreshCallback?.call(_refresh);
    _loadApps().then((_) {
      if (widget.initialNotification != null) {
        _populateFromNotification(widget.initialNotification!);
      }
    });
  }

  Future<void> _populateFromNotification(NotificationModel notification) async {
    _titleController.text = notification.title;
    _bodyController.text = notification.body;
    _imageUrlController.text = notification.imageUrl ?? '';
    _nicknameController.text = notification.nickname ?? '';
    if (notification.data != null) {
      _customData.clear();
      _customData.addAll(Map<String, String>.from(
        notification.data!.map((key, value) => MapEntry(key, value.toString())),
      ));
    }
    
    // Set the selected app
    if (notification.app.id.isNotEmpty) {
      final app = _apps.firstWhere(
        (a) => a.id == notification.app.id,
        orElse: () => notification.app,
      );
      setState(() {
        _selectedApp = app;
      });
      await _loadAppData(app);
      
      // Set the selected target based on notification
      if (notification.topic != null) {
        final topic = _topics.firstWhere(
          (t) => t.name == notification.topic,
          orElse: () => _topics.first,
        );
        setState(() {
          _selectedTopic = topic;
          _selectedDevice = null;
          _selectedCondition = null;
        });
      } else if (notification.condition != null) {
        // Try to find matching condition - this is complex, so we'll just set first if available
        if (_conditions.isNotEmpty) {
          setState(() {
            _selectedCondition = _conditions.first;
            _selectedDevice = null;
            _selectedTopic = null;
          });
        }
      } else if (notification.tokens != null && notification.tokens!.isNotEmpty) {
        final token = notification.tokens!.first;
        final device = _devices.firstWhere(
          (d) => d.notificationToken == token,
          orElse: () => _devices.first,
        );
        setState(() {
          _selectedDevice = device;
          _selectedTopic = null;
          _selectedCondition = null;
        });
      }
    }
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
    // Reload app to get latest topics, devices, and conditions
    final updatedApp = await _appStorage.getAppById(app.id);
    if (updatedApp != null) {
      setState(() {
        _topics = updatedApp.topics;
        _devices = updatedApp.devices;
        _conditions = updatedApp.conditions;
        _selectedTopic = null;
        _selectedDevice = null;
        _selectedCondition = null;
      });
    } else {
      setState(() {
        _topics = app.topics;
        _devices = app.devices;
        _conditions = app.conditions;
        _selectedTopic = null;
        _selectedDevice = null;
        _selectedCondition = null;
      });
    }
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

  String _getSelectedTargetText() {
    if (_selectedDevice != null) {
      return 'Device: ${_selectedDevice!.name}';
    } else if (_selectedTopic != null) {
      return 'Topic: ${_selectedTopic!.name}';
    } else if (_selectedCondition != null) {
      return 'Condition: ${_selectedCondition!.name}';
    }
    return 'Select target...';
  }

  Future<void> _showTargetSelector() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Target',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const HeroIcon(HeroIcons.xMark),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Devices section
            if (_devices.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Devices',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              ..._devices.map((device) => ListTile(
                leading: const HeroIcon(HeroIcons.devicePhoneMobile, size: 20),
                title: Text(device.name),
                subtitle: Text(
                  device.notificationToken,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: _selectedDevice?.id == device.id,
                onTap: () {
                  setState(() {
                    _selectedDevice = device;
                    _selectedTopic = null;
                    _selectedCondition = null;
                  });
                  Navigator.pop(context);
                },
              )),
              const Divider(),
            ],
            // Topics section
            if (_topics.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Text(
                  'Topics',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              ..._topics.map((topic) => ListTile(
                leading: const HeroIcon(HeroIcons.hashtag, size: 20),
                title: Text(topic.name),
                selected: _selectedTopic?.id == topic.id,
                onTap: () {
                  setState(() {
                    _selectedTopic = topic;
                    _selectedDevice = null;
                    _selectedCondition = null;
                  });
                  Navigator.pop(context);
                },
              )),
              const Divider(),
            ],
            // Conditions section
            if (_conditions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Text(
                  'Conditions',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              ..._conditions.map((condition) => ListTile(
                leading: CircleAvatar(
                  radius: 12,
                  child: Text(
                    condition.operator,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(condition.name),
                subtitle: Text(
                  '${condition.topicIds.length} topics, ${condition.conditionIds.length} nested',
                ),
                selected: _selectedCondition?.id == condition.id,
                onTap: () {
                  setState(() {
                    _selectedCondition = condition;
                    _selectedDevice = null;
                    _selectedTopic = null;
                  });
                  Navigator.pop(context);
                },
              )),
            ],
            if (_devices.isEmpty && _topics.isEmpty && _conditions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No targets available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an app')),
      );
      return;
    }

    if (_selectedDevice == null && _selectedTopic == null && _selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a device, topic, or condition')),
      );
      return;
    }

    try {
      final imageUrl = _imageUrlController.text.trim();
      
      // Determine topic or condition string
      String? topic;
      String? condition;
      List<String>? tokens;
      
      if (_selectedDevice != null) {
        tokens = [_selectedDevice!.notificationToken];
      } else if (_selectedTopic != null) {
        topic = _selectedTopic!.name;
      } else if (_selectedCondition != null) {
        condition = _selectedCondition!.buildConditionString(_topics, _conditions);
      }
      
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        app: _selectedApp!,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        data: _customData.isEmpty ? null : _customData,
        topic: topic,
        condition: condition,
        tokens: tokens,
        createdAt: DateTime.now(),
        nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
      );

      final success = await _fcmService.sendNotification(
        app: _selectedApp!,
        title: notification.title,
        body: notification.body,
        imageUrl: notification.imageUrl,
        data: notification.data,
        topic: notification.topic,
        condition: notification.condition,
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
          _imageUrlController.clear();
          _nicknameController.clear();
          setState(() {
            _selectedDevice = null;
            _selectedTopic = null;
            _selectedCondition = null;
            _customData.clear();
          });
          widget.onDataChanged?.call();
        }
      }
    } catch (e) {
      final imageUrl = _imageUrlController.text.trim();
      
      // Determine topic or condition string
      String? topic;
      String? condition;
      List<String>? tokens;
      
      if (_selectedDevice != null) {
        tokens = [_selectedDevice!.notificationToken];
      } else if (_selectedTopic != null) {
        topic = _selectedTopic!.name;
      } else if (_selectedCondition != null) {
        condition = _selectedCondition!.buildConditionString(_topics, _conditions);
      }
      
      // Parse error to extract JSON error if available
      String? errorString = _parseError(e);
      
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        app: _selectedApp!,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        data: _customData.isEmpty ? null : _customData,
        topic: topic,
        condition: condition,
        tokens: tokens,
        createdAt: DateTime.now(),
        sent: false,
        error: errorString,
        nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
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
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _nicknameController.dispose();
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
                    TextFormField(
                      controller: _imageUrlController,
                      enabled: _selectedApp != null,
                      decoration: const InputDecoration(
                        labelText: 'Image URL (Optional)',
                        hintText: 'https://example.com/image.png',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nicknameController,
                      enabled: _selectedApp != null,
                      decoration: const InputDecoration(
                        labelText: 'Nickname (Optional)',
                        hintText: 'e.g., Welcome Message, Daily Reminder',
                        border: OutlineInputBorder(),
                      ),
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
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Target',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _selectedApp != null ? _showTargetSelector : null,
                      icon: const HeroIcon(HeroIcons.chevronDown),
                      label: Text(_getSelectedTargetText()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    if (_selectedDevice == null && _selectedTopic == null && _selectedCondition == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Please select a device, topic, or condition',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ActionSlider.standard(
              width: double.infinity,
              height: 56,
              backgroundColor: Theme.of(context).colorScheme.surface,
              action: (controller) async {
                if (_selectedApp == null || 
                    (_selectedDevice == null && _selectedTopic == null && _selectedCondition == null)) {
                  controller.reset();
                  return;
                }
                controller.loading();
                await _sendNotification();
                controller.success();
                await Future.delayed(const Duration(seconds: 1));
                controller.reset();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HeroIcon(HeroIcons.paperAirplane, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Slide to Send',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
    String? condition,
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
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      topic: topic ?? this.topic,
      condition: condition ?? this.condition,
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


