import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:heroicons/heroicons.dart';
import '../models/app_model.dart';
import '../models/user_model.dart';
import '../services/app_storage_service.dart';
import '../services/user_storage_service.dart';

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
  final _tokenInputController = TextEditingController();
  final _appStorage = AppStorageService();
  final _userStorage = UserStorageService();
  String? _selectedJsonFilePath;
  String? _selectedJsonFileName;
  String? _selectedLogoFilePath;
  String? _selectedLogoFileName;
  List<UserModel> _testTokenUsers = [];

  @override
  void initState() {
    super.initState();
    if (widget.app != null) {
      _nameController.text = widget.app!.name;
      _packageController.text = widget.app!.packageName;
      _selectedJsonFilePath = widget.app!.jsonFilePath;
      _selectedJsonFileName = widget.app!.jsonFilePath.split('/').last;
      _selectedLogoFilePath = widget.app!.logoFilePath;
      if (_selectedLogoFilePath != null) {
        _selectedLogoFileName = _selectedLogoFilePath!.split('/').last;
      }
      _loadTestTokenUsers();
    }
  }

  Future<void> _loadTestTokenUsers() async {
    if (widget.app != null) {
      final users = await _userStorage.getUsers(widget.app!.id);
      // Filter users that are test tokens (name starts with "Test Device")
      setState(() {
        _testTokenUsers = users.where((u) => u.name.startsWith('Test Device')).toList();
      });
    }
  }

  Future<void> _addTestToken() async {
    final token = _tokenInputController.text.trim();
    if (token.isEmpty) return;

    // Check if token already exists
    if (_testTokenUsers.any((u) => u.notificationToken == token)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This token is already added'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _tokenInputController.clear();
      return;
    }

    // For new apps, we'll use a temporary appId and update it when saving
    // For existing apps, use the actual appId
    final appId = widget.app?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final testUserNumber = _testTokenUsers.length + 1;
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      appId: appId,
      name: 'Test Device $testUserNumber',
      notificationToken: token,
      createdAt: DateTime.now(),
    );

    // Only save to storage if app already exists
    if (widget.app != null) {
      await _userStorage.saveUser(user);
    }
    
    setState(() {
      _testTokenUsers.add(user);
    });
    _tokenInputController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test token added')),
      );
    }
  }

  Future<void> _removeTestToken(UserModel user) async {
    await _userStorage.deleteUser(user.id);
    setState(() {
      _testTokenUsers.removeWhere((u) => u.id == user.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test token removed')),
      );
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
        
        // Validate JSON
        try {
          final jsonContent = await file.readAsString();
          json.decode(jsonContent);
          
          // Copy file to app documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final fileName = 'app_${timestamp}_credentials.json';
          final savedFile = File('${appDir.path}/$fileName');
          await savedFile.writeAsString(jsonContent);
          
          setState(() {
            _selectedJsonFilePath = savedFile.path;
            _selectedJsonFileName = result.files.single.name;
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

  Future<void> _pickLogoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        
        // Copy file to app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final extension = filePath.split('.').last;
        final fileName = 'app_${timestamp}_logo.$extension';
        final savedFile = File('${appDir.path}/$fileName');
        await file.copy(savedFile.path);
        
        setState(() {
          _selectedLogoFilePath = savedFile.path;
          _selectedLogoFileName = result.files.single.name;
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
    
    if (_selectedJsonFilePath == null || _selectedJsonFilePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a JSON file'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final appId = widget.app?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    // Save test token users with correct appId
    for (var user in _testTokenUsers) {
      final updatedUser = UserModel(
        id: user.id,
        appId: appId,
        name: user.name,
        notificationToken: user.notificationToken,
        createdAt: user.createdAt,
      );
      await _userStorage.saveUser(updatedUser);
    }

    final app = AppModel(
      id: appId,
      name: _nameController.text.trim(),
      packageName: _packageController.text.trim(),
      jsonFilePath: _selectedJsonFilePath!,
      logoFilePath: _selectedLogoFilePath,
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
    _tokenInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                        child: Column(
                          children: [
                            if (_selectedLogoFilePath != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedLogoFilePath!),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _pickLogoFile,
                              icon: const HeroIcon(HeroIcons.photo),
                              label: Text(_selectedLogoFileName ?? 'Pick Logo'),
                            ),
                            if (_selectedLogoFileName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _selectedLogoFileName!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
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
                      OutlinedButton.icon(
                        onPressed: _pickJsonFile,
                        icon: const HeroIcon(HeroIcons.folderOpen),
                        label: Text(_selectedJsonFileName ?? 'Select JSON File'),
                      ),
                      if (_selectedJsonFileName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Selected: $_selectedJsonFileName',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'Select your Firebase service account JSON file. This file is required.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Test Notification Tokens',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add FCM device tokens for testing. Each token will be automatically created as a user.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tokenInputController,
                              decoration: const InputDecoration(
                                labelText: 'FCM Token',
                                hintText: 'Enter FCM device token',
                                border: OutlineInputBorder(),
                              ),
                              onFieldSubmitted: (_) => _addTestToken(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _addTestToken,
                            icon: const HeroIcon(HeroIcons.plus),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      if (_testTokenUsers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _testTokenUsers.map((user) {
                            final displayToken = user.notificationToken.length > 25
                                ? '${user.notificationToken.substring(0, 25)}...'
                                : user.notificationToken;
                            return Tooltip(
                              message: user.notificationToken,
                              child: Chip(
                                label: Text(
                                  displayToken,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                deleteIcon: const HeroIcon(HeroIcons.xMark, size: 16),
                                onDeleted: () => _removeTestToken(user),
                                avatar: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(
                                    user.name.replaceAll('Test Device ', ''),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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
}
