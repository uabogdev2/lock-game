import 'dart:async';
import 'package:flutter/foundation.dart'; // For ChangeNotifier or other state management
import 'package:in_app_purchase/in_app_purchase.dart';
// For platform-specific purchase completion (Android).
// Import 'package:in_app_purchase_android/in_app_purchase_android.dart' if needed for specific Android features.
// Import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart' for specific iOS features.


// Define a class that can be used with a ChangeNotifierProvider or other state management
class IAPService extends ChangeNotifier {
  // Product ID for "Remove Ads" - IMPORTANT: This must match the ID configured on the app stores.
  // Example: 'com.yourcompany.yourapp.remove_ads'
  static const String _noAdsProductId = 'com.example.lockgame.no_ads'; // TODO: Update with actual package name

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _storeAvailable = false;
  bool get storeAvailable => _storeAvailable;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  List<PurchaseDetails> _purchases = []; // Mostly for history or pending purchases
  List<PurchaseDetails> get purchases => _purchases;

  bool _noAdsPurchased = false;
  bool get noAdsPurchased => _noAdsPurchased;

  // To notify UI or other services about purchase status changes
  // This can be a simple bool notifier or a more complex state object.
  // ValueNotifier<bool> noAdsPurchasedNotifier = ValueNotifier<bool>(false);


  Future<void> initialize() async {
    _storeAvailable = await _iap.isAvailable();
    print('IAP Store available: $_storeAvailable');

    if (_storeAvailable) {
      await loadProducts();
      await _verifyPastPurchases(); // Check for existing non-consumable purchases

      _purchaseSubscription = _iap.purchaseStream.listen(
        (purchaseDetailsList) {
          _handlePurchaseUpdates(purchaseDetailsList);
        },
        onDone: () {
          print('IAP purchaseStream done.');
          _purchaseSubscription?.cancel();
        },
        onError: (error) {
          print('IAP purchaseStream error: $error');
          // Handle error, maybe retry or log
        },
      );
    }
    notifyListeners(); // Notify about store availability and initial noAds status
  }

  Future<void> loadProducts() async {
    if (!_storeAvailable) {
      print('IAP Store not available. Cannot load products.');
      return;
    }
    print('Loading IAP products...');
    final ProductDetailsResponse response = await _iap.queryProductDetails({_noAdsProductId}.toSet());

    if (response.error != null) {
      print('Error loading products: ${response.error}');
      _products = [];
      notifyListeners();
      return;
    }
    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
    print('Products loaded: ${_products.map((p) => p.id).join(', ')}');
    notifyListeners();
  }

  Future<void> _verifyPastPurchases() async {
    // This is a simplified way. For non-consumables, the purchase stream on init
    // should also bring up past purchases that are not yet "finished".
    // However, explicitly checking can be useful or if you store state locally.
    // For a robust solution, you'd typically query the native IAP APIs or use a server.

    // The purchaseStream is the primary way to get purchase updates, including restored ones.
    // If a non-consumable was purchased but not "finished" (completed), it should appear in the stream.
    // For "no_ads", once purchased and finished, its state should be persisted (e.g., FirestoreService or local prefs).
    // Here, we'll assume that if it's in active purchases from the stream and it's for no_ads, we set the flag.
    // This method is more of a placeholder for a more robust restoration check if needed beyond the stream.

    // A simple check: if any product among existing purchases (after stream init) is _noAdsProductId
    // and is purchased/restored, then _noAdsPurchased = true.
    // This will be handled by _handlePurchaseUpdates when the stream first emits.
    print("Verifying past purchases (delegated to initial purchase stream handling).");
  }


  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchase in purchaseDetailsList) {
      print('Handling purchase update for: ${purchase.productID}, status: ${purchase.status}');
      if (purchase.status == PurchaseStatus.pending) {
        print('Purchase pending: ${purchase.productID}');
        // Show pending UI if necessary
      } else {
        if (purchase.status == PurchaseStatus.error) {
          print('Purchase error for ${purchase.productID}: ${purchase.error}');
          // Handle error, show error UI
        } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
          print('Purchase successful/restored: ${purchase.productID}');
          bool valid = await _verifyPurchase(purchase); // Server-side validation is best practice
          if (valid) {
            await _deliverPurchase(purchase);
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
              print('Purchase completed: ${purchase.productID}');
            }
          } else {
            print('Purchase validation failed for ${purchase.productID}');
            // Handle invalid purchase
          }
        }
        // For consumables, you'd consume them here after delivery.
        // For non-consumables like 'no_ads', once delivered and completed, the state is set.
      }
    }
    notifyListeners();
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // IMPORTANT: For real apps, VERIFY THE PURCHASE ON YOUR SERVER using purchaseDetails.verificationData
    // This is to prevent fraud. For a client-only app or simple non-consumable,
    // client-side checks might be deemed sufficient for some use cases, but it's less secure.
    print('Purchase verification (client-side basic): ${purchaseDetails.productID}');
    return true; // Assume valid for this skeleton
  }

  Future<void> _deliverPurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID == _noAdsProductId) {
      print('Delivering "No Ads" purchase.');
      _noAdsPurchased = true;
      // Here, you would also typically:
      // 1. Persist this state (e.g., using FirestoreService to update UserModel, or SharedPreferences)
      //    Example: await _firestoreService.updateNoAdsPurchase(userId, true);
      // 2. Notify other parts of your app that ads should be disabled.
      //    (This IAPService can be a ChangeNotifier, and UI can listen to `noAdsPurchased`)
      // noAdsPurchasedNotifier.value = true; // If using ValueNotifier

      print('"No Ads" feature delivered.');
    }
    notifyListeners();
  }

  Future<void> buyNoAds() async {
    if (!_storeAvailable) {
      print('IAP Store not available. Cannot buy product.');
      // Optionally, inform the user via UI
      return;
    }
    final ProductDetails? productDetails = _products.firstWhere(
      (p) => p.id == _noAdsProductId,
      orElse: () {
        print('Product $_noAdsProductId not found.');
        return null;
      },
    );

    if (productDetails == null) {
      print('Cannot buy "No Ads": Product details not found. Try loading products again.');
      // Optionally, inform the user or try to load products again
      await loadProducts(); // Attempt to reload
      return;
    }

    if (_noAdsPurchased) {
        print('"No Ads" already purchased.');
        // Optionally, inform the user via UI
        return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    try {
      // For non-consumable, use buyNonConsumable. For consumable, use buyConsumable.
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Error buying non-consumable: $e');
      // Handle buy error, e.g. user cancelled, network issue
    }
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      print('IAP Store not available. Cannot restore purchases.');
      // Optionally, inform the user via UI
      return;
    }
    try {
      await _iap.restorePurchases();
      print('Restore purchases initiated.');
      // The purchaseStream will emit PurchaseStatus.restored for any restored items.
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }

  void dispose() {
    print('Disposing IAPService.');
    _purchaseSubscription?.cancel();
    // noAdsPurchasedNotifier.dispose(); // If using ValueNotifier
    super.dispose(); // If extending ChangeNotifier
  }
}
