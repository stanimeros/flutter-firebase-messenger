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
import '../services/gemini_service.dart';
import '../services/token_service.dart';
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
  final _geminiService = GeminiService();
  final _tokenService = TokenService();

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
  
  // Cached access tokens for the selected app
  String? _geminiToken;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    // Add listeners to text controllers to rebuild when text changes
    _titleController.addListener(() {
      setState(() {});
    });
    _bodyController.addListener(() {
      setState(() {});
    });
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
        } else {
          _selectedApp = apps.first;
        }
        // Load app data and generate tokens
        if (_selectedApp != null) {
          _loadAppData(_selectedApp!);
        }
      } else {
        _selectedApp = null;
        _geminiToken = null;
        _fcmToken = null;
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
    
    // Generate access tokens for the selected app
    await _generateTokensForApp(app.id);
  }

  Future<void> _generateTokensForApp(String appId) async {
    try {
      // Generate both tokens in parallel for better performance
      final tokens = await _tokenService.getBothTokens(appId);
      setState(() {
        _geminiToken = tokens['gemini'];
        _fcmToken = tokens['fcm'];
      });
    } catch (e) {
      // If token generation fails, clear tokens and let services generate them on demand
      setState(() {
        _geminiToken = null;
        _fcmToken = null;
      });
      debugPrint('Failed to generate tokens for app $appId: $e');
    }
  }

  Future<void> _showRefineDialog(String fieldType, String originalText) async {
    if (_selectedApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an app first')),
      );
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _RefineDialog(
        fieldType: fieldType,
        originalText: originalText,
        geminiService: _geminiService,
        appId: _selectedApp!.id,
        accessToken: _geminiToken,
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (fieldType == 'title') {
          _titleController.text = result;
        } else {
          _bodyController.text = result;
        }
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


  void _showSendConfirmation() {
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
                  'Send Notification',
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
              'Are you sure you want to send this notification?',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ActionSlider.standard(
              width: double.infinity,
              height: 64,
              backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
              toggleColor: CustomAppTheme.primaryCyan,
              action: (controller) async {
                controller.loading();
                await _sendNotification();
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
            const SizedBox(height: 16),
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
        accessToken: _fcmToken,
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
                          setState(() {
                            _selectedApp = app;
                          });
                          _loadAppData(app);
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
                    Stack(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          enabled: _selectedApp != null,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'Notification title',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.only(right: 48, top: 16, bottom: 16, left: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter title';
                            }
                            return null;
                          },
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _titleController,
                            builder: (context, value, child) {
                              final isEnabled = _selectedApp != null && value.text.isNotEmpty;
                              return IconButton(
                                icon: HeroIcon(
                                  HeroIcons.sparkles,
                                  color: isEnabled
                                      ? null
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                                ),
                                onPressed: isEnabled
                                    ? () => _showRefineDialog('title', _titleController.text)
                                    : null,
                                tooltip: 'Refine title',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                visualDensity: VisualDensity.compact,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        TextFormField(
                          controller: _bodyController,
                          enabled: _selectedApp != null,
                          decoration: const InputDecoration(
                            labelText: 'Body',
                            hintText: 'Notification body text',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.only(right: 48, top: 16, bottom: 16, left: 16),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter body';
                            }
                            return null;
                          },
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _bodyController,
                            builder: (context, value, child) {
                              final isEnabled = _selectedApp != null && value.text.isNotEmpty;
                              return IconButton(
                                icon: HeroIcon(
                                  HeroIcons.sparkles,
                                  color: isEnabled
                                      ? null
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                                ),
                                onPressed: isEnabled
                                    ? () => _showRefineDialog('body', _bodyController.text)
                                    : null,
                                tooltip: 'Refine body',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                visualDensity: VisualDensity.compact,
                              );
                            },
                          ),
                        ),
                      ],
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
            ElevatedButton(
              onPressed: () {
                // Dismiss keyboard
                FocusScope.of(context).unfocus();
                
                // Validate app selection
                if (_selectedApp == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an app')),
                  );
                  return;
                }

                // Validate form fields first
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                
                // Validate target selection
                if (_selectedDevice == null && _selectedTopic == null && _selectedCondition == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a device, topic, or condition')),
                  );
                  return;
                }
                
                _showSendConfirmation();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: CustomAppTheme.primaryCyan,
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HeroIcon(HeroIcons.paperAirplane, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Send Notification',
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

class _RefineDialog extends StatefulWidget {
  final String fieldType;
  final String originalText;
  final GeminiService geminiService;
  final String appId;
  final String? accessToken;

  const _RefineDialog({
    required this.fieldType,
    required this.originalText,
    required this.geminiService,
    required this.appId,
    this.accessToken,
  });

  @override
  State<_RefineDialog> createState() => _RefineDialogState();
}

class _RefineDialogState extends State<_RefineDialog> {
  final _resultController = TextEditingController();
  final _promptController = TextEditingController();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _resultController.text = widget.originalText;
    _promptController.text = 'Refine the following notification ${widget.fieldType == 'title' ? 'title' : 'body'}, make it more engaging and use emojis where appropriate. ${widget.fieldType == 'title' ? 'Keep it concise and attention-grabbing.' : 'Keep it clear and compelling.'} Return only the refined ${widget.fieldType == 'title' ? 'title' : 'body'} without any additional text:';
  }

  @override
  void dispose() {
    _resultController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateRefinedText() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final refinedText = await widget.geminiService.refineText(
        widget.appId,
        widget.originalText,
        _promptController.text.trim(),
        accessToken: widget.accessToken!,
      );

      if (refinedText != null && mounted) {
        setState(() {
          _resultController.text = refinedText;
          _isGenerating = false;
        });
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No response from Gemini'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        debugPrint('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const HeroIcon(HeroIcons.sparkles, size: 24),
          const SizedBox(width: 8),
          Text('Refine ${widget.fieldType == 'title' ? 'Title' : 'Body'}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Text: ${widget.originalText}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'Enter your prompt...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              minLines: 3,
              enabled: !_isGenerating,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateRefinedText,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const HeroIcon(HeroIcons.sparkles, size: 20),
              label: Text(_isGenerating ? 'Generating...' : 'Generate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomAppTheme.primaryCyan,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _resultController,
              decoration: InputDecoration(
                labelText: 'Result',
                hintText: 'Refined text will appear here...',
                border: const OutlineInputBorder(),
                enabled: !_isGenerating,
              ),
              maxLines: widget.fieldType == 'title' ? 2 : 5,
              minLines: widget.fieldType == 'title' ? 1 : 3,
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _resultController.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _resultController.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: CustomAppTheme.primaryCyan,
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply'),
        ),
      ],
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


