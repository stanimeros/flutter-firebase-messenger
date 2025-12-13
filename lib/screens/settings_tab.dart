import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../services/secure_storage_service.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _secureStorage = SecureStorageService();
  bool _hasCredentials = false;
  String? _credentialsInfo;

  @override
  void initState() {
    super.initState();
    _checkCredentials();
  }

  Future<void> _checkCredentials() async {
    final hasCreds = await _secureStorage.hasCredentials();
    if (hasCreds) {
      final creds = await _secureStorage.getCredentialsAsMap();
      if (creds != null && creds.containsKey('project_id')) {
        setState(() {
          _hasCredentials = true;
          _credentialsInfo = 'Project: ${creds['project_id']}';
        });
      } else {
        setState(() {
          _hasCredentials = true;
          _credentialsInfo = 'Credentials loaded';
        });
      }
    } else {
      setState(() {
        _hasCredentials = false;
        _credentialsInfo = null;
      });
    }
  }

  Future<void> _pickAndSaveJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final jsonContent = await file.readAsString();

        // Validate JSON
        try {
          await _secureStorage.saveCredentials(jsonContent);
          await _checkCredentials();

          if (mounted) {
            ShadToaster.of(context).show(
              const ShadToast(
                description: Text('Credentials saved successfully'),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ShadToaster.of(context).show(
              ShadToast.destructive(
                description: Text('Invalid JSON file: $e'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('Error loading file: $e'),
          ),
        );
      }
    }
  }

  Future<void> _deleteCredentials() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Delete Credentials'),
        description: const Text(
            'Are you sure you want to delete saved Firebase credentials?'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _secureStorage.deleteCredentials();
      await _checkCredentials();

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('Credentials deleted'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const HeroIcon(HeroIcons.shieldCheck),
                      const SizedBox(width: 8),
                      Text(
                        'Firebase Credentials',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_hasCredentials)
                    ShadAlert(
                      title: Row(
                        children: [
                          const HeroIcon(
                            HeroIcons.checkCircle,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Credentials loaded',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_credentialsInfo != null)
                                  Text(
                                    _credentialsInfo!,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          ShadIconButton(
                            icon: const HeroIcon(HeroIcons.trash),
                            onPressed: _deleteCredentials,
                          ),
                        ],
                      ),
                    )
                  else
                    ShadAlert.destructive(
                      title: const Row(
                        children: [
                          HeroIcon(
                            HeroIcons.exclamationTriangle,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No credentials loaded',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  ShadButton(
                    onPressed: _pickAndSaveJson,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        HeroIcon(HeroIcons.folderOpen),
                        SizedBox(width: 8),
                        Text('Select Firebase Service Account JSON'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your Firebase service account JSON file. This will be securely stored on your device.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HeroIcon(HeroIcons.informationCircle),
                      const SizedBox(width: 8),
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Firebase Cloud Messenger',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Version: 0.1.0'),
                  const SizedBox(height: 16),
                  const Text(
                    'This app allows you to send push notifications through Firebase Cloud Messaging. Add your mobile apps, configure them with server keys, and send notifications to topics or specific device tokens.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

