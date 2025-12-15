import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/custom_app_bar.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://firebase.google.com/docs/cloud-messaging/send/v1-api'));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text('Help & Documentation'),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: HeroIcon(HeroIcons.informationCircle), text: 'App Guide'),
              Tab(icon: HeroIcon(HeroIcons.bookOpen), text: 'FCM Docs'),
            ],
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: [
                _buildAppGuide(),
                _buildDocumentation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppGuide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HeroIcon(HeroIcons.plusCircle, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Creating Apps',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '1. Navigate to the Apps tab',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the + button (Floating Action Button) to create a new app.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '2. Fill in App Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• App Name: Enter a descriptive name for your mobile app\n'
                    '• Package Name: Enter the package name (e.g., com.example.app)\n'
                    '• Logo: Optionally select an image file for your app logo\n'
                    '• JSON File: Select your Firebase service account JSON file (required). For the JSON file, ask your developer to create a key through a service account with Firebase Cloud Messaging Admin API as role.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '3. Save the App',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap "Save App" to store your app configuration. The JSON file will be securely saved on your device.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HeroIcon(HeroIcons.hashtag, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Managing Topics & Users',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '1. Open App Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap on any app from the Apps tab to view its details.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '2. Add Topics',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'In the Topics tab, enter a topic name and tap "Add Topic". Topics allow you to send messages to groups of devices that have subscribed to that topic.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '3. Add Users',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'In the Users tab, enter a user name and their FCM device token, then tap "Add User". Users represent individual devices that can receive notifications.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HeroIcon(HeroIcons.bell, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Creating Notifications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '1. Select an App',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Navigate to the Create tab and select an app from the dropdown. All fields will be enabled once an app is selected.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '2. Enter Notification Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Title: The notification title (required)\n'
                    '• Body: The notification message text (required)',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '3. Choose Recipients',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select either:\n'
                    '• A Topic: Send to all devices subscribed to that topic\n'
                    '• One or more Users: Send to specific devices by selecting users\n'
                    'Note: You can only select either a topic OR users, not both.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '4. Add Custom Data (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add custom key-value pairs that will be sent with the notification. This data can be used by your app to perform custom actions.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '5. Send Notification',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap "Send Notification" to deliver the message. The notification will be saved to history with its delivery status.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HeroIcon(HeroIcons.clock, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Viewing History',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The History tab shows all notifications you\'ve sent, including:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Sent status (success or failed)\n'
                    '• App name and details\n'
                    '• Notification content\n'
                    '• Recipients (topic or users)\n'
                    '• Timestamp\n'
                    '• Error messages (if any)',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You can expand each notification to see full details, delete individual notifications, or clear all history.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HeroIcon(HeroIcons.shieldCheck, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Security Notes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '• Firebase service account JSON files are stored securely on your device\n'
                    '• Never share your service account credentials\n'
                    '• Keep your device secure to protect stored credentials\n'
                    '• Device tokens should be kept private',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentation() {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
