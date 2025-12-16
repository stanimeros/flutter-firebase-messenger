import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/app_model.dart';
import '../services/app_storage_service.dart';
import 'app_detail_screen.dart';
import 'create_app_screen.dart';

class AppsScreen extends StatefulWidget {
  final void Function(VoidCallback)? onRefreshCallback;
  final VoidCallback? onDataChanged;

  const AppsScreen({
    super.key,
    this.onRefreshCallback,
    this.onDataChanged,
  });

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> with AutomaticKeepAliveClientMixin {
  final _appStorage = AppStorageService();
  List<AppModel> _apps = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.onRefreshCallback?.call(_loadApps);
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

  Future<bool> _deleteApp(AppModel app) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete App'),
        content: Text('Are you sure you want to delete ${app.name}? This action cannot be undone.'),
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
      return true;
    }
    return false;
  }

  Widget _buildAppLogo(String? logoImageData, String appName) {
    if (logoImageData == null || logoImageData.isEmpty) {
      return _buildDefaultAvatar(appName);
    }

    try {
      final imageBytes = base64Decode(logoImageData);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          imageBytes,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(appName);
          },
        ),
      );
    } catch (e) {
      return _buildDefaultAvatar(appName);
    }
  }

  Widget _buildDefaultAvatar(String appName) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          appName.isNotEmpty ? appName[0].toUpperCase() : 'A',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                  const SizedBox(height: 12),
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
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _apps.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final app = _apps[index];
                return Dismissible(
                  key: Key(app.id),
                  direction: DismissDirection.endToStart,
                  background: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      child: const HeroIcon(
                        HeroIcons.trash,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    final deleted = await _deleteApp(app);
                    if (deleted) {
                      widget.onDataChanged?.call();
                    }
                    return deleted;
                  },
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: _buildAppLogo(app.imageData, app.name),
                      title: Text(app.name),
                      subtitle: Text(app.packageName),
                      trailing: IconButton(
                        icon: const HeroIcon(HeroIcons.arrowRight),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppDetailScreen(
                                app: app,
                                onDataChanged: () {
                                  _loadApps();
                                  widget.onDataChanged?.call();
                                },
                              ),
                            ),
                          ).then((result) {
                            _loadApps();
                            if (result == true) {
                              widget.onDataChanged?.call();
                            }
                          });
                        },
                        tooltip: 'View Details',
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppDetailScreen(
                              app: app,
                              onDataChanged: () {
                                _loadApps();
                                widget.onDataChanged?.call();
                              },
                            ),
                          ),
                        ).then((result) {
                          _loadApps();
                          if (result == true) {
                            widget.onDataChanged?.call();
                          }
                        });
                      },
                    ),
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
            widget.onDataChanged?.call();
          }
        },
        icon: const HeroIcon(HeroIcons.plus),
        label: const Text('Create App'),
      ),
    );
  }
}

