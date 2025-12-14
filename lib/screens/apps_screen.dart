import 'dart:io';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/app_model.dart';
import '../services/app_storage_service.dart';
import 'app_detail_screen.dart';
import 'create_app_screen.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

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

  Widget _buildAppLogo(String? logoFilePath) {
    if (logoFilePath == null) {
      return const CircleAvatar(
        child: HeroIcon(HeroIcons.devicePhoneMobile),
      );
    }

    return FutureBuilder<bool>(
      future: File(logoFilePath).exists(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              File(logoFilePath),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const CircleAvatar(
                  child: HeroIcon(HeroIcons.devicePhoneMobile),
                );
              },
            ),
          );
        }
        return const CircleAvatar(
          child: HeroIcon(HeroIcons.devicePhoneMobile),
        );
      },
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
                    leading: _buildAppLogo(app.logoFilePath),
                    title: Text(app.name),
                    subtitle: Text(app.packageName),
                    trailing: IconButton(
                      icon: const HeroIcon(HeroIcons.arrowRight),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppDetailScreen(app: app),
                          ),
                        ).then((_) => _loadApps());
                      },
                      tooltip: 'View Details',
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

