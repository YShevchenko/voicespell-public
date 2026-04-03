import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// One-time IAP service for VoiceSpell Premium.
/// Product ID: voicespell_premium — $3.99 one-time purchase.
class IAPService extends ChangeNotifier {
  static final IAPService instance = IAPService._();
  IAPService._();

  static const String _productId = 'voicespell_premium';

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  ProductDetails? _product;
  ProductDetails? get product => _product;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final InAppPurchase _iap = InAppPurchase.instance;

  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {},
    );

    // Load product details
    final response =
        await _iap.queryProductDetails({_productId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    }

    // Restore any existing purchases
    await _iap.restorePurchases();

    notifyListeners();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID == _productId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          _isPremium = true;
          _isPurchasing = false;
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
        } else if (purchase.status == PurchaseStatus.error) {
          _isPurchasing = false;
        } else if (purchase.status == PurchaseStatus.canceled) {
          _isPurchasing = false;
        }
      }
    }
    notifyListeners();
  }

  Future<bool> purchase() async {
    if (_product == null) return false;
    _isPurchasing = true;
    notifyListeners();

    final param = PurchaseParam(productDetails: _product!);
    try {
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (_) {
      _isPurchasing = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  String get priceString => _product?.price ?? '\$3.99';

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
