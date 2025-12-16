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
import '../services/messaging_service.dart';
import '../widgets/custom_app_theme.dart';
import '../utils/tools.dart';

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
  final _messagingService = MessagingService();

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
    _nicknameController.text = notification.nickname;
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
      } else if (notification.token != null && notification.token!.isNotEmpty) {
        final device = _devices.firstWhere(
          (d) => d.notificationToken == notification.token,
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
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
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
      String? token;
      
      if (_selectedDevice != null) {
        token = _selectedDevice!.notificationToken;
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
        token: token,
        createdAt: DateTime.now(),
        nickname: _nicknameController.text.trim(),
      );

      final success = await _messagingService.sendNotification(
        app: _selectedApp!,
        title: notification.title,
        body: notification.body,
        imageUrl: notification.imageUrl,
        data: notification.data,
        topic: notification.topic,
        condition: notification.condition,
        token: notification.token,
      );

      final errorData = success ? null : ErrorUtils.extractErrorCodeAndMessage(Exception('Failed to send notification'));
      final savedNotification = notification.copyWith(
        sent: success,
        resultCode: success ? '200' : errorData?['code'],
        resultMessage: success ? 'Notification sent successfully' : errorData?['message'],
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
      String? token;
      
      if (_selectedDevice != null) {
        token = _selectedDevice!.notificationToken;
      } else if (_selectedTopic != null) {
        topic = _selectedTopic!.name;
      } else if (_selectedCondition != null) {
        condition = _selectedCondition!.buildConditionString(_topics, _conditions);
      }
      
      // Parse error to extract code and message
      final errorData = ErrorUtils.extractErrorCodeAndMessage(e);
      
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        app: _selectedApp!,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        data: _customData.isEmpty ? null : _customData,
        topic: topic,
        condition: condition,
        token: token,
        createdAt: DateTime.now(),
        sent: false,
        nickname: _nicknameController.text.trim(),
        resultCode: errorData?['code'],
        resultMessage: errorData?['message'],
      );

      await _notificationStorage.saveNotification(notification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification.resultMessage ?? 'Error occurred'),
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
                      controller: _nicknameController,
                      enabled: _selectedApp != null,
                      decoration: const InputDecoration(
                        labelText: 'Nickname',
                        hintText: 'e.g., Welcome Message, Daily Reminder',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a nickname';
                        }
                        return null;
                      },
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
                    InkWell(
                      onTap: _selectedApp != null ? _showTargetSelector : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedApp != null
                                ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)
                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            if (_selectedDevice != null)
                              const HeroIcon(HeroIcons.devicePhoneMobile, size: 20)
                            else if (_selectedTopic != null)
                              const HeroIcon(HeroIcons.hashtag, size: 20)
                            else if (_selectedCondition != null)
                              const HeroIcon(HeroIcons.funnel, size: 20)
                            else
                              HeroIcon(
                                HeroIcons.cursorArrowRays,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getSelectedTargetText(),
                                style: TextStyle(
                                  color: _selectedApp != null
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            HeroIcon(
                              HeroIcons.chevronDown,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ],
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
              backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
              toggleColor: CustomAppTheme.primaryCyan,
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
                  const Text(
                    'Slide to Send',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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


