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
                      const HeroIcon(HeroIcons.key, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'API Access Requirements',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'To use this app, you need to enable the following APIs in your Google Cloud project:\n\n'
                    '1. Gemini API\n'
                    '   • Required for text refinement features\n'
                    '2. Firebase API\n'
                    '   • Required for sending notifications\n'
                    '3. Service Account Permissions\n'
                    '   • Your service account must have the "Firebase Cloud Messaging API Admin" role'
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
                      const HeroIcon(HeroIcons.plusCircle, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Apps',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to create an app. Enter name, package name, and upload Firebase service account JSON. Swipe left to delete.',
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
                        'Devices & Conditions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Open an app to manage:\n'
                    '• Devices: Add device tokens\n'
                    '• Topics: Create topic groups\n'
                    '• Conditions: Combine topics/conditions with AND/OR\n'
                    'Tap + in each tab to add. Swipe left to delete. Tap edit icon to modify.',
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
                        'Notifications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Select app\n'
                    '2. Enter nickname\n'
                    '3. Enter title and body\n'
                    '4. Select target (device, topic, or condition)\n'
                    '5. Add image URL or custom data (optional)\n'
                    '6. Slide to send',
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
                        'History',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'View all sent notifications with nickname and timestamp. Tap to see details, duplicate, or resend. Swipe left to delete.',
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
                        'Security',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Service account JSON files are encrypted and stored securely on your device.',
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
