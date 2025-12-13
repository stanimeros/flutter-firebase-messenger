import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/app_model.dart';
import '../services/app_storage_service.dart';

class AddAppTab extends StatefulWidget {
  const AddAppTab({super.key});

  @override
  State<AddAppTab> createState() => _AddAppTabState();
}

class _AddAppTabState extends State<AddAppTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _packageController = TextEditingController();
  final _serverKeyController = TextEditingController();
  final _appStorage = AppStorageService();
  List<AppModel> _apps = [];

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await _appStorage.getApps();
    setState(() {
      _apps = apps;
    });
  }

  Future<void> _saveApp() async {
    if (!_formKey.currentState!.validate()) return;

    final app = AppModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      packageName: _packageController.text.trim(),
      serverKey: _serverKeyController.text.trim().isEmpty 
          ? null 
          : _serverKeyController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _appStorage.saveApp(app);
    _nameController.clear();
    _packageController.clear();
    _serverKeyController.clear();
    _loadApps();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App saved successfully')),
      );
    }
  }

  Future<void> _deleteApp(AppModel app) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete App'),
        content: Text('Are you sure you want to delete ${app.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _appStorage.deleteApp(app.id);
      _loadApps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App deleted')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _packageController.dispose();
    _serverKeyController.dispose();
    super.dispose();
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add Mobile App',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
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
                    TextFormField(
                      controller: _serverKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Server Key (Optional)',
                        hintText: 'AAA...',
                        border: OutlineInputBorder(),
                        helperText: 'FCM Server Key from Firebase Console',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ShadButton(
                      onPressed: _saveApp,
                      child: const Text('Save App'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Saved Apps',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (_apps.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    HeroIcon(
                      HeroIcons.inbox,
                      size: 48,
                      style: HeroIconStyle.outline,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No apps added yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._apps.map((app) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: HeroIcon(HeroIcons.devicePhoneMobile),
                    ),
                    title: Text(app.name),
                    subtitle: Text(app.packageName),
                    trailing: IconButton(
                      icon: const HeroIcon(HeroIcons.trash),
                      onPressed: () => _deleteApp(app),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

