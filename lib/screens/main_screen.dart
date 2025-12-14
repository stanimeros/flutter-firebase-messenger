import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'add_app_screen.dart';
import 'create_notification_screen.dart';
import 'history_screen.dart';
import 'help_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AddAppScreen(),
    CreateNotificationScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Messenger'),
        actions: [
          IconButton(
            icon: const HeroIcon(HeroIcons.questionMarkCircle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpScreen(),
                ),
              );
            },
            tooltip: 'Help',
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: HeroIcon(HeroIcons.plusCircle),
            label: 'Apps',
          ),
          BottomNavigationBarItem(
            icon: HeroIcon(HeroIcons.bell),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: HeroIcon(HeroIcons.clock),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

