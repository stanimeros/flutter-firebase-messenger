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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Credentials saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid JSON file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCredentials() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Credentials'),
        content: const Text(
            'Are you sure you want to delete saved Firebase credentials?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _secureStorage.deleteCredentials();
      await _checkCredentials();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credentials deleted')),
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
          Card(
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
                    Card(
                      color: Colors.green.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const HeroIcon(
                              HeroIcons.checkCircle,
                              color: Colors.green,
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
                                      color: Colors.green,
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
                            IconButton(
                              icon: const HeroIcon(HeroIcons.trash),
                              onPressed: _deleteCredentials,
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      color: Colors.orange.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const HeroIcon(
                              HeroIcons.exclamationTriangle,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'No credentials loaded',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
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
          Card(
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

