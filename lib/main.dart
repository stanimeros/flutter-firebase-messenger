import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/paywall_screen.dart';
import 'services/purchases_service.dart';
import 'widgets/custom_app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize RevenueCat Purchases
  try {
    await PurchasesService.initialize();
  } catch (e) {
    // If initialization fails, app will still run but paywall won't work
    debugPrint('Failed to initialize Purchases: $e');
  }
  
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
      home: const PaywallGate(),
    );
  }
}

/// Gate widget that checks premium status and shows paywall or main screen
class PaywallGate extends StatefulWidget {
  const PaywallGate({super.key});

  @override
  State<PaywallGate> createState() => _PaywallGateState();
}

class _PaywallGateState extends State<PaywallGate> {
  bool _isLoading = true;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _setupListener();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await PurchasesService.isPremium();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _isLoading = false;
      });
    }
  }

  void _setupListener() {
    // Periodically check for premium status updates
    // This handles cases where purchase completes in background
    // Check every 2 seconds for the first 10 seconds after initialization
    int checks = 0;
    void checkPeriodically() {
      if (checks < 5 && mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          _checkPremiumStatus();
          checks++;
          checkPeriodically();
        });
      }
    }
    checkPeriodically();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: CustomAppTheme.darkBackground,
        body: const Center(
          child: CircularProgressIndicator(
            color: CustomAppTheme.primaryCyan,
          ),
        ),
      );
    }

    // Show paywall if not premium, otherwise show main screen
    return _isPremium ? const MainScreen() : const PaywallScreen();
  }
}
