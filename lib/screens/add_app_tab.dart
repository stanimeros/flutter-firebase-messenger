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
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('App saved successfully'),
        ),
      );
    }
  }

  Future<void> _deleteApp(AppModel app) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Delete App'),
        description: Text('Are you sure you want to delete ${app.name}?'),
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
      await _appStorage.deleteApp(app.id);
      _loadApps();
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('App deleted'),
          ),
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
          ShadCard(
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
                    ShadInputFormField(
                      controller: _nameController,
                      placeholder: const Text('My Awesome App'),
                      label: const Text('App Name'),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter app name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      controller: _packageController,
                      placeholder: const Text('com.example.app'),
                      label: const Text('Package Name'),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter package name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ShadTextareaFormField(
                      controller: _serverKeyController,
                      placeholder: const Text('AAA...'),
                      label: const Text('Server Key (Optional)'),
                      description: const Text('FCM Server Key from Firebase Console'),
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
            ShadCard(
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
            ..._apps.map((app) => ShadCard(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: HeroIcon(HeroIcons.devicePhoneMobile),
                    ),
                    title: Text(app.name),
                    subtitle: Text(app.packageName),
                    trailing: ShadIconButton(
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

