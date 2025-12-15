import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/purchases_service.dart';
import '../widgets/custom_app_theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;
  bool _isRestoring = false;
  Offerings? _offerings;
  Package? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final offerings = await PurchasesService.getOfferings();
      setState(() {
        _offerings = offerings;
        // Select the first available package by default
        if (offerings?.current != null && offerings!.current!.availablePackages.isNotEmpty) {
          _selectedPackage = offerings.current!.availablePackages.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load subscription options: $e'),
            backgroundColor: CustomAppTheme.darkError,
          ),
        );
      }
    }
  }

  Future<void> _purchasePackage() async {
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subscription plan'),
          backgroundColor: CustomAppTheme.darkError,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await PurchasesService.purchasePackage(_selectedPackage!);
      
      if (success) {
        // Re-check premium status to ensure it's updated
        await PurchasesService.isPremium();
        
        if (mounted) {
          // Premium unlocked, the app will automatically navigate away
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to Premium! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase was cancelled'),
              backgroundColor: CustomAppTheme.darkError,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: CustomAppTheme.darkError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isRestoring = true;
    });

    try {
      final success = await PurchasesService.restorePurchases();
      
      // Re-check premium status to ensure it's updated
      if (success) {
        await PurchasesService.isPremium();
      }
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchases restored successfully! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No purchases found to restore'),
              backgroundColor: CustomAppTheme.darkError,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore purchases: $e'),
            backgroundColor: CustomAppTheme.darkError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  String _getPackageDisplayName(PackageType packageType) {
    switch (packageType) {
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.annual:
        return 'Annual';
      case PackageType.sixMonth:
        return '6 Months';
      case PackageType.threeMonth:
        return '3 Months';
      case PackageType.twoMonth:
        return '2 Months';
      case PackageType.weekly:
        return 'Weekly';
      case PackageType.lifetime:
        return 'Lifetime';
      case PackageType.custom:
        return 'Custom';
      case PackageType.unknown:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomAppTheme.darkBackground,
      body: SafeArea(
        child: _isLoading && _offerings == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: CustomAppTheme.primaryCyan,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Logo/Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            CustomAppTheme.primaryPurple,
                            CustomAppTheme.primaryBlue,
                            CustomAppTheme.primaryCyan,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.rocket_launch,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      'Unlock Premium',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Subtitle
                    Text(
                      'Get unlimited access to all premium features',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: CustomAppTheme.darkOnSurface.withValues(alpha: 0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Features list
                    _buildFeatureItem(
                      icon: HeroIcons.sparkles,
                      text: 'Unlimited notifications',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: HeroIcons.bolt,
                      text: 'Priority support',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: HeroIcons.shieldCheck,
                      text: 'Advanced security',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: HeroIcons.chartBar,
                      text: 'Analytics & insights',
                    ),
                    const SizedBox(height: 48),
                    // Subscription packages
                    if (_offerings?.current != null &&
                        _offerings!.current!.availablePackages.isNotEmpty)
                      ..._offerings!.current!.availablePackages.map((package) {
                        final isSelected = _selectedPackage?.identifier == package.identifier;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPackageCard(
                            package: package,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedPackage = package;
                              });
                            },
                          ),
                        );
                      })
                    else
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: CustomAppTheme.darkCardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CustomAppTheme.darkError,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: CustomAppTheme.darkError,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No subscription packages available',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: CustomAppTheme.darkError,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please configure your RevenueCat offerings',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: CustomAppTheme.darkOnSurface.withValues(alpha: 0.7),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    // Purchase button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _purchasePackage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomAppTheme.primaryCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Text(
                              'Subscribe Now',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Restore purchases button
                    TextButton(
                      onPressed: _isRestoring ? null : _restorePurchases,
                      child: _isRestoring
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CustomAppTheme.primaryCyan,
                              ),
                            )
                          : const Text('Restore Purchases'),
                    ),
                    const SizedBox(height: 24),
                    // Terms and privacy
                    Text(
                      'By subscribing, you agree to our Terms of Service and Privacy Policy. Subscription will auto-renew unless cancelled.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: CustomAppTheme.darkOnSurface.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required HeroIcons icon,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CustomAppTheme.primaryCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HeroIcon(
            icon,
            color: CustomAppTheme.primaryCyan,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: CustomAppTheme.darkOnSurface,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard({
    required Package package,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CustomAppTheme.darkCardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? CustomAppTheme.primaryCyan
                : CustomAppTheme.darkOnSurface.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? CustomAppTheme.primaryCyan
                      : CustomAppTheme.darkOnSurface.withValues(alpha: 0.3),
                  width: 2,
                ),
                color: isSelected
                    ? CustomAppTheme.primaryCyan
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.black,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPackageDisplayName(package.packageType),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.storeProduct.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CustomAppTheme.darkOnSurface.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            Text(
              package.storeProduct.priceString,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: CustomAppTheme.primaryCyan,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

