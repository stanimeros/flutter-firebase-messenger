import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

class PurchasesService {
  static const String _entitlementId = 'premium';
  
  static const String _androidApiKey = 'test_ZTunwknVYEPYcHIlWPKWveGKtXt';
  static const String _iosApiKey = 'test_ZTunwknVYEPYcHIlWPKWveGKtXt';
  
  static bool _isInitialized = false;

  /// Initialize RevenueCat Purchases SDK
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
      
      await Purchases.configure(
        PurchasesConfiguration(apiKey)
          ..appUserID = null, // Let RevenueCat generate anonymous ID
      );
      
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Purchases: $e');
    }
  }

  /// Check if user has premium entitlement
  static Future<bool> isPremium() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active[_entitlementId] != null;
    } catch (e) {
      // If there's an error, assume not premium (fail closed)
      return false;
    }
  }

  /// Get available offerings (subscription packages)
  static Future<Offerings?> getOfferings() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      return await Purchases.getOfferings();
    } catch (e) {
      return null;
    }
  }

  /// Purchase a package
  static Future<bool> purchasePackage(Package package) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final result = await Purchases.purchase(PurchaseParams.package(package));
      final customerInfo = result.customerInfo;
      
      // Check if premium entitlement is now active
      return customerInfo.entitlements.active[_entitlementId] != null;
    } on PurchasesError catch (e) {
      // User cancelled or error occurred
      if (e.code != PurchasesErrorCode.purchaseCancelledError) {
        rethrow;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Restore purchases
  static Future<bool> restorePurchases() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.active[_entitlementId] != null;
    } catch (e) {
      return false;
    }
  }

  /// Get current customer info
  static Future<CustomerInfo?> getCustomerInfo() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      return await Purchases.getCustomerInfo();
    } catch (e) {
      return null;
    }
  }

}