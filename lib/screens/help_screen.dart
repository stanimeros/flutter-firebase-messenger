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
        title: Text('Help'), 
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HeroIcon(HeroIcons.informationCircle, size: 18),
                    SizedBox(width: 6),
                    Text('App Guide'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HeroIcon(HeroIcons.bookOpen, size: 18),
                    SizedBox(width: 6),
                    Text('FCM Docs'),
                  ],
                ),
              ),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 12),
                  const Text(
                    '1. Navigate to the Apps tab',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the + button (Floating Action Button) to create a new app.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '2. Fill in App Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• App Name: Enter a descriptive name\n'
                    '• Package Name: Enter the package name (e.g., com.example.app)\n'
                    '• Logo: Optionally select an image file\n'
                    '• JSON File: Select your Firebase service account JSON file (required)',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '3. Save the App',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap "Save App" to store your app configuration. The JSON file is securely encrypted on your device.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HeroIcon(HeroIcons.hashtag, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Managing Topics & Devices',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Open App Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap on any app from the Apps tab to view its details.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '2. Add Topics',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'In the Topics tab, tap the + button and enter a topic name. Topics allow you to send messages to groups of devices subscribed to that topic.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '3. Add Devices',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'In the Devices tab, tap the + button and enter a device name with their FCM device token. Devices represent individual devices that can receive notifications.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 12),
                  const Text(
                    '1. Select an App',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Navigate to the Create tab and select an app from the dropdown.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '2. Enter Notification Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Title: The notification title (required)\n'
                    '• Body: The notification message text (required)',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '3. Choose Recipients',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toggle between Topics or Devices, then select:\n'
                    '• One Topic: Send to all devices subscribed to that topic\n'
                    '• One Device: Send to a specific device\n'
                    'Note: You must select either a topic OR a device (required).',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '4. Add Custom Data (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add custom key-value pairs that will be sent with the notification.',
                  ),
                  const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 12),
                  const Text(
                    'The History tab shows all notifications you\'ve sent. Expand any notification to see:\n'
                    '• Sent status (success or failed)\n'
                    '• App name and details\n'
                    '• Notification content\n'
                    '• Recipients (topic or user)\n'
                    '• Timestamp\n'
                    '• Error messages (if any)',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Swipe left on any notification to delete it.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 12),
                  const Text(
                    '• Firebase service account JSON files are encrypted and stored securely\n'
                    '• Never share your service account credentials\n'
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
