import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/constant/colors.dart';
import '../core/constant/firestore_collection.dart';

class InAppPurchaseProvider extends ChangeNotifier {
  InAppPurchaseProvider() {
    debugPrint('InAppPurchaseProvider initialized');
    fetchOfferings();
    fetchCreditPacks();
    checkSubscriptionStatus();
  }

  static const entitlementCatalog = 'catalog_access';
  static const entitlementLegacy = 'premium';
  static const virtualCurrencyCode = 'CRD';
  static const creditPackIds = [
    'credits_pack_5',
    'credits_pack_15',
    'credits_pack_40',
  ];
  static const _creditsApiBase =
      'https://web-production-b405a.up.railway.app/v1/api/credits';

  bool isSubscribed = false;
  bool isTrial = false;
  Offering? offering;
  bool isLoading = false;
  bool isLoadingPacks = false;
  bool creditPacksFailed = false;
  List<Package>? availablePackages;
  List<StoreProduct> creditPacks = [];

  /// Saldo de créditos en RevenueCat (Virtual Currency `CRD`).
  int creditBalance = 0;

  /// Créditos antiguos guardados en Firestore `users.credits`.
  int legacyCredits = 0;

  bool? _canPost;
  DateTime? _nextRefillDate;

  /// Identificador del último gasto aceptado por el backend (para reembolso).
  String? lastSpendId;
  String? lastSpendSource;

  /// Créditos ganados en la última compra de suscripción.
  int lastPurchaseGain = 0;

  int get totalCredits => creditBalance + legacyCredits;

  DateTime? get nextRefillDate => _nextRefillDate;

  bool? get canPost => _canPost;

  set canPost(bool? value) {
    _canPost = value;
    notifyListeners();
  }

  void fetchOfferings() async {
    debugPrint('Fetching offerings...');
    isLoading = true;
    notifyListeners();

    try {
      Offerings? offerings = await Purchases.getOfferings();
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        offering = offerings.current;
        availablePackages = offering?.availablePackages;
        debugPrint(
          'Offerings loaded: ${availablePackages?.length} packages found.',
        );
      } else {
        debugPrint('No available packages found.');
      }
    } on PlatformException catch (e) {
      debugPrint('RevenueCat error while fetching offerings: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCreditPacks() async {
    debugPrint('Fetching credit packs...');
    isLoadingPacks = true;
    creditPacksFailed = false;
    notifyListeners();

    try {
      final products = await Purchases.getProducts(
        creditPackIds,
        productCategory: ProductCategory.nonSubscription,
      );
      products.sort((a, b) => a.price.compareTo(b.price));
      creditPacks = products;
      debugPrint('Credit packs loaded: ${creditPacks.length} products found.');
      if (creditPacks.isEmpty) {
        debugPrint(
          'Store returned no credit packs: check that the product IDs exist and are active in Play Console / App Store Connect.',
        );
      }
    } on PlatformException catch (e) {
      debugPrint('RevenueCat error while fetching credit packs: $e');
      creditPacksFailed = true;
    }

    isLoadingPacks = false;
    notifyListeners();
  }

  /// True si el producto de [p] ofrece una prueba gratuita en la tienda.
  static bool packageHasFreeTrial(Package? p) {
    if (p == null) return false;
    final product = p.storeProduct;
    final options = product.subscriptionOptions;
    if (options != null && options.any((o) => o.freePhase != null)) {
      return true;
    }
    final intro = product.introductoryPrice;
    return intro != null && intro.price == 0;
  }

  Package? get monthlyPackage {
    final package =
        availablePackages
            ?.where((pkg) => pkg.packageType == PackageType.monthly)
            .toList()
            .cast<Package?>()
            .firstOrNull;
    return package;
  }

  Package? get yearlyPackage {
    final package =
        availablePackages
            ?.where((pkg) => pkg.packageType == PackageType.annual)
            .toList()
            .cast<Package?>()
            .firstOrNull;
    return package;
  }

  String get annualSavingsPercentage {
    final annual = yearlyPackage;
    final monthly = monthlyPackage;

    if (annual == null || monthly == null) return "85%"; // Fallback

    try {
      final annualPrice = annual.storeProduct.price;
      final monthlyPrice = monthly.storeProduct.price;

      if (monthlyPrice == 0) return "85%";

      final totalMonthlyCost = monthlyPrice * 12;
      final savings =
          ((totalMonthlyCost - annualPrice) / totalMonthlyCost) * 100;

      return "${savings.toStringAsFixed(0)}%";
    } catch (e) {
      debugPrint('Error calculating savings: $e');
      return "85%";
    }
  }

  Future<bool> buySubscription(Package package) async {
    try {
      debugPrint('Attempting to purchase: ${package.storeProduct.identifier}');
      final creditsBefore = totalCredits;
      await Purchases.purchase(PurchaseParams.package(package));
      debugPrint('Purchase successful.');
      await checkSubscriptionStatus();
      await refreshCredits(invalidate: true);
      final gain = totalCredits - creditsBefore;
      lastPurchaseGain = gain > 0 ? gain : 0;
      return isSubscribed;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('Purchase cancelled by user.');
      } else {
        debugPrint('Purchase failed: $e');
      }
      return false;
    }
  }

  Future<bool> buyCreditPack(StoreProduct product) async {
    try {
      debugPrint('Attempting to purchase credit pack: ${product.identifier}');
      await Purchases.purchase(PurchaseParams.storeProduct(product));
      debugPrint('Credit pack purchase successful.');
      await refreshCredits(invalidate: true);
      return true;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('Credit pack purchase cancelled by user.');
        return false;
      }
      debugPrint('Credit pack purchase failed: $e');
      Get.snackbar('sorry'.tr, 'wentWrong'.tr, colorText: AppColors.textColor);
      return false;
    }
  }

  EntitlementInfo? _activeEntitlement(CustomerInfo customerInfo) {
    final catalog = customerInfo.entitlements.all[entitlementCatalog];
    if (catalog != null && catalog.isActive) return catalog;
    final legacy = customerInfo.entitlements.all[entitlementLegacy];
    if (legacy != null && legacy.isActive) return legacy;
    return null;
  }

  void _applyCustomerInfo(CustomerInfo customerInfo) {
    final entitlement = _activeEntitlement(customerInfo);
    if (entitlement != null) {
      isSubscribed = true;
      isTrial = entitlement.periodType == PeriodType.trial;
      _nextRefillDate =
          entitlement.expirationDate != null
              ? DateTime.tryParse(entitlement.expirationDate!)
              : null;
      debugPrint(
        "Subscription is active (${entitlement.identifier}). Trial: $isTrial. Next refill: $_nextRefillDate",
      );
    } else {
      isSubscribed = false;
      isTrial = false;
      _nextRefillDate = null;
      debugPrint("No active subscription found.");
    }
  }

  Future<void> checkSubscriptionStatus() async {
    debugPrint('Checking subscription status...');
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _applyCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint("Error checking subscription status: $e");
    }
    await refreshCredits();
  }

  /// Lee el saldo de RevenueCat (y los créditos antiguos de Firestore).
  /// Con [invalidate] fuerza una lectura fresca tras una compra o un gasto.
  Future<void> refreshCredits({bool invalidate = false}) async {
    try {
      if (invalidate) {
        await Purchases.invalidateVirtualCurrenciesCache();
      }
      final currencies = await Purchases.getVirtualCurrencies();
      creditBalance = currencies.all[virtualCurrencyCode]?.balance ?? 0;
    } catch (e) {
      debugPrint('Error fetching virtual currencies: $e');
    }
    legacyCredits = await _fetchLegacyCredits();
    _canPost = totalCredits > 0;
    debugPrint(
      'Credits refreshed: rc=$creditBalance legacy=$legacyCredits total=$totalCredits',
    );
    notifyListeners();
  }

  Future<int> _fetchLegacyCredits() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection(firebaseUserCollection)
              .doc(uid)
              .get();
      final value = snapshot.data()?['credits'];
      return value is num ? value.toInt() : 0;
    } catch (e) {
      debugPrint('Error reading legacy credits: $e');
      return 0;
    }
  }

  Future<void> restorePurchases() async {
    debugPrint('Restoring purchases...');
    try {
      CustomerInfo restoredInfo = await Purchases.restorePurchases();
      _applyCustomerInfo(restoredInfo);

      if (isSubscribed) {
        debugPrint("Restore successful. Subscription active.");
        Get.snackbar(
          'successful'.tr,
          'purchaseRestoreSuccessfully'.tr,
          colorText: AppColors.textColor,
        );
      } else {
        debugPrint("Restore complete, but no active subscription found.");
        Get.snackbar(
          'sorry'.tr,
          'You have no active subscription',
          colorText: AppColors.textColor,
        );
      }
    } catch (e) {
      debugPrint("Error restoring purchases: $e");
      Get.snackbar(
        'sorry'.tr,
        'errorRestoringPurchases'.tr,
        colorText: AppColors.textColor,
      );
    }
    await refreshCredits(invalidate: true);
  }

  Future<void> check() async {
    debugPrint('can post called');
    await refreshCredits();
    canPost = totalCredits > 0;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Aplica el saldo devuelto por el backend según la fuente del movimiento.
  Future<void> _applyBalance(String? source, int? newBalance, int delta) async {
    if (source == 'legacy') {
      legacyCredits = newBalance ?? (legacyCredits + delta).clamp(0, 1 << 31);
    } else {
      creditBalance = newBalance ?? (creditBalance + delta).clamp(0, 1 << 31);
      try {
        await Purchases.invalidateVirtualCurrenciesCache();
      } catch (e) {
        debugPrint('Error invalidating virtual currencies cache: $e');
      }
    }
    _canPost = totalCredits > 0;
    notifyListeners();
  }

  /// Gasta 1 crédito a través del backend (RevenueCat o reserva legacy).
  Future<bool> deductCredit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$_creditsApiBase/spend'),
            headers: await _authHeaders(),
            body: jsonEncode({'uId': uid}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        debugPrint(
          '❌ Credit spend rejected (${response.statusCode}): ${response.body}',
        );
        return false;
      }

      final data = jsonDecode(response.body);
      if (data is! Map || data['ok'] != true) {
        debugPrint('❌ Credit spend not ok: ${response.body}');
        return false;
      }

      final balance = data['balance'];
      final int? newBalance = balance is num ? balance.toInt() : null;
      final source = data['source']?.toString();
      final spendId = data['spendId'];
      lastSpendId = spendId is String ? spendId : null;
      lastSpendSource = source;
      await _applyBalance(source, newBalance, -1);
      debugPrint(
        '✅ Credit spent from $source (spendId=$lastSpendId). rc=$creditBalance legacy=$legacyCredits',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error deducting credit: $e');
      return false;
    }
  }

  /// Devuelve el último crédito gastado si la creación falló después del cobro.
  Future<bool> refundLastSpend() async {
    final spendId = lastSpendId;
    if (spendId == null) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$_creditsApiBase/refund'),
            headers: await _authHeaders(),
            body: jsonEncode({'spendId': spendId}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        debugPrint(
          '❌ Credit refund rejected (${response.statusCode}): ${response.body}',
        );
        return false;
      }

      final data = jsonDecode(response.body);
      if (data is! Map || data['ok'] != true) {
        debugPrint('❌ Credit refund not ok: ${response.body}');
        return false;
      }

      final balance = data['balance'];
      final int? newBalance = balance is num ? balance.toInt() : null;
      final source = data['source']?.toString() ?? lastSpendSource;
      await _applyBalance(source, newBalance, 1);
      lastSpendId = null;
      debugPrint(
        '✅ Credit refunded to $source. rc=$creditBalance legacy=$legacyCredits',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error refunding credit: $e');
      return false;
    }
  }
}
