import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat IAP service for managing premium access
class IAPService {
  static final IAPService instance = IAPService._();
  IAPService._();

  static const String _apiKeyIOS = 'YOUR_REVENUECAT_IOS_KEY';
  static const String _apiKeyAndroid = 'YOUR_REVENUECAT_ANDROID_KEY';
  static const String _entitlementID = 'premium';
  static const String _productID = 'voice_spell_premium';

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> initialize() async {
    try {
      // Configure RevenueCat
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration configuration;
      if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_apiKeyIOS);
      } else if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_apiKeyAndroid);
      } else {
        return;
      }

      await Purchases.configure(configuration);

      // Check initial premium status
      await checkPremiumStatus();

      // Listen to customer info updates
      Purchases.addCustomerInfoUpdateListener(_customerInfoUpdateListener);
    } catch (e) {
      print('Error initializing IAP: $e');
    }
  }

  void _customerInfoUpdateListener(CustomerInfo customerInfo) {
    _updatePremiumStatus(customerInfo);
  }

  Future<void> checkPremiumStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updatePremiumStatus(customerInfo);
    } catch (e) {
      print('Error checking premium status: $e');
      // Default to false on error
      _isPremium = false;
    }
  }

  void _updatePremiumStatus(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.all[_entitlementID];
    _isPremium = entitlement != null && entitlement.isActive;
  }

  Future<bool> purchase() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;

      if (offering == null) {
        print('No offerings available');
        return false;
      }

      final package = offering.availablePackages.firstWhere(
        (pkg) => pkg.storeProduct.identifier == _productID,
        orElse: () => offering.availablePackages.first,
      );

      final customerInfo = await Purchases.purchasePackage(package);

      _updatePremiumStatus(customerInfo);
      return _isPremium;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        print('Purchase cancelled');
      } else {
        print('Purchase error: $e');
      }
      return false;
    } catch (e) {
      print('Unexpected purchase error: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updatePremiumStatus(customerInfo);
      return _isPremium;
    } catch (e) {
      print('Error restoring purchases: $e');
      return false;
    }
  }

  Future<String?> getPriceString() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;

      if (offering == null) return null;

      final package = offering.availablePackages.firstWhere(
        (pkg) => pkg.storeProduct.identifier == _productID,
        orElse: () => offering.availablePackages.first,
      );

      return package.storeProduct.priceString;
    } catch (e) {
      print('Error getting price: $e');
      return null;
    }
  }
}
