import 'dart:io';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/app_model.dart';
import '../services/app_storage_service.dart';
import 'app_detail_screen.dart';
import 'create_app_screen.dart';

class AddAppTab extends StatefulWidget {
  const AddAppTab({super.key});

  @override
  State<AddAppTab> createState() => _AddAppTabState();
}

class _AddAppTabState extends State<AddAppTab> {
  final _appStorage = AppStorageService();
  List<AppModel> _apps = [];

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload apps when returning to this screen
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await _appStorage.getApps();
    setState(() {
      _apps = apps;
    });
  }

  Future<void> _deleteApp(AppModel app) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete App'),
        content: Text('Are you sure you want to delete ${app.name}?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: _apps.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HeroIcon(
                    HeroIcons.inbox,
                    size: 64,
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
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first app',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _apps.length,
              itemBuilder: (context, index) {
                final app = _apps[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: app.logoFilePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              File(app.logoFilePath!),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const CircleAvatar(
                                  child: HeroIcon(HeroIcons.devicePhoneMobile),
                                );
                              },
                            ),
                          )
                        : const CircleAvatar(
                            child: HeroIcon(HeroIcons.devicePhoneMobile),
                          ),
                    title: Text(app.name),
                    subtitle: Text(app.packageName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const HeroIcon(HeroIcons.arrowRight),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AppDetailScreen(app: app),
                              ),
                            ).then((_) => _loadApps());
                          },
                        ),
                        IconButton(
                          icon: const HeroIcon(HeroIcons.trash),
                          onPressed: () => _deleteApp(app),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppDetailScreen(app: app),
                        ),
                      ).then((_) => _loadApps());
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateAppScreen(),
            ),
          );
          if (result == true) {
            _loadApps();
          }
        },
        icon: const HeroIcon(HeroIcons.plus),
        label: const Text('Create App'),
      ),
    );
  }
}

