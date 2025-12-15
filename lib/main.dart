import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'widgets/custom_app_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fire Message',
      theme: CustomAppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}
