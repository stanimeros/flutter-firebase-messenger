import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'add_app_tab.dart';
import 'create_notification_tab.dart';
import 'history_tab.dart';
import 'settings_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Cloud Messenger'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: HeroIcon(HeroIcons.plusCircle), text: 'Add App'),
            Tab(icon: HeroIcon(HeroIcons.bell), text: 'Create'),
            Tab(icon: HeroIcon(HeroIcons.clock), text: 'History'),
            Tab(icon: HeroIcon(HeroIcons.cog6Tooth), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AddAppTab(),
          CreateNotificationTab(),
          HistoryTab(),
          SettingsTab(),
        ],
      ),
    );
  }
}

