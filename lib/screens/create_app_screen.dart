import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:heroicons/heroicons.dart';
import '../models/app_model.dart';
import '../services/app_storage_service.dart';
import '../services/secure_storage_service.dart';
import '../widgets/custom_app_bar.dart';

class CreateAppScreen extends StatefulWidget {
  final AppModel? app;
  
  const CreateAppScreen({super.key, this.app});

  @override
  State<CreateAppScreen> createState() => _CreateAppScreenState();
}

class _CreateAppScreenState extends State<CreateAppScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _packageController = TextEditingController();
  final _appStorage = AppStorageService();
  final _secureStorage = SecureStorageService();
  Map<String, dynamic>? _serviceAccount;
  String? _selectedLogoImageData; // Base64 encoded image data

  @override
  void initState() {
    super.initState();
    if (widget.app != null) {
      _nameController.text = widget.app!.name;
      _packageController.text = widget.app!.packageName;
      _selectedLogoImageData = widget.app!.imageData;
      // Load existing JSON credentials from secure storage
      _loadExistingCredentials();
    }
  }

  Future<void> _loadExistingCredentials() async {
    if (widget.app != null) {
      final credentials = await _secureStorage.getAppCredentials(widget.app!.id);
      if (credentials != null) {
        setState(() {
          _serviceAccount = credentials;
        });
      }
    }
  }

  Future<void> _pickJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        
        // Validate JSON and create GoogleKeyModel
        try {
          final jsonContent = await file.readAsString();
          final serviceAccount = jsonDecode(jsonContent) as Map<String, dynamic>;
          
          // Validate the model
          if (serviceAccount.isEmpty) {
            throw Exception('Invalid service account JSON. Missing required fields.');
          }
          
          // Store GoogleKeyModel
          setState(() {
            _serviceAccount = serviceAccount;
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid JSON file: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
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
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildLogoPreview() {
    if (_selectedLogoImageData == null || _selectedLogoImageData!.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Icon(
          Icons.image,
          size: 50,
          color: Colors.grey,
        ),
      );
    }

    try {
      final imageBytes = base64Decode(_selectedLogoImageData!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          imageBytes,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Icon(
                Icons.image,
                size: 50,
                color: Colors.grey,
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Icon(
          Icons.image,
          size: 50,
          color: Colors.grey,
        ),
      );
    }
  }

  Future<void> _pickLogoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        
        // Read image as bytes and convert to base64
        final imageBytes = await file.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        
        setState(() {
          _selectedLogoImageData = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveApp() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if we have GoogleKeyModel (new file) or need to load from secure storage (existing app)
    Map<String, dynamic>? serviceAccount = _serviceAccount;
    
    // If editing existing app and no new JSON selected, try to load from secure storage
    if (serviceAccount == null && widget.app != null) {
      serviceAccount = await _secureStorage.getAppCredentials(widget.app!.id);
    }
    
    if (serviceAccount == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a JSON file'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final appId = widget.app?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    if (serviceAccount == null) {
      return;
    }
    
    // Save JSON content to secure storage using the model
    await _secureStorage.saveAppCredentials(appId, serviceAccount);
    
    final app = AppModel(
      id: appId,
      name: _nameController.text.trim(),
      packageName: _packageController.text.trim(),
      imageData: _selectedLogoImageData,
      createdAt: widget.app?.createdAt ?? DateTime.now(),
    );

    await _appStorage.saveApp(app);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.app == null ? 'App saved successfully' : 'App updated successfully')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _packageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(widget.app == null ? 'Create App' : 'Edit App'),
      ),
      body: SingleChildScrollView(
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
                        'App Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      // Logo picker
                      Center(
                        child: GestureDetector(
                          onTap: _pickLogoFile,
                          child: Stack(
                            children: [
                              _buildLogoPreview(),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const HeroIcon(
                                    HeroIcons.camera,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'App Name',
                          hintText: 'My Awesome App',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter app name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _packageController,
                        decoration: const InputDecoration(
                          labelText: 'Package Name',
                          hintText: 'com.example.app',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter package name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_serviceAccount == null)
                        OutlinedButton.icon(
                          onPressed: _pickJsonFile,
                          icon: const HeroIcon(HeroIcons.folderOpen),
                          label: const Text('Select JSON File'),
                        ),
                      if (_serviceAccount != null) ...[
                        const SizedBox(height: 16),
                        _buildJsonFieldsExpansion(),
                      ],
                      if (_serviceAccount == null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Select your Firebase service account JSON file. This file is required.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveApp,
                child: Text(widget.app == null ? 'Save App' : 'Update App'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJsonFieldsExpansion() {
    if (_serviceAccount == null) return const SizedBox.shrink();

    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Project ID: ${_serviceAccount!['project_id']}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_serviceAccount!.isNotEmpty) ...[
                  ..._serviceAccount!.entries
                      .where((entry) => 
                          entry.key != 'project_id' && 
                          entry.key != 'client_email' && 
                          entry.key != 'private_key')
                      .map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextFormField(
                        initialValue: _formatJsonValue(entry.value),
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: entry.key,
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        maxLines: entry.value is String && entry.value.length > 100 ? 3 : 1,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _serviceAccount = null;
                    });
                  },
                  icon: const HeroIcon(HeroIcons.trash),
                  label: const Text('Clear Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatJsonValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    return value.toString();
  }
}

class _AddTokenDialog extends StatefulWidget {
  const _AddTokenDialog();

  @override
  State<_AddTokenDialog> createState() => _AddTokenDialogState();
}

class _AddTokenDialogState extends State<_AddTokenDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Test Notification Token'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter a name for this test device',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'FCM Token',
                  hintText: 'Enter FCM device token',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a token';
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
                'name': _nameController.text.trim(),
                'token': _tokenController.text.trim(),
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
