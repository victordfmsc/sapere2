import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import 'package:sapere/providers/user_provider.dart';

import '../core/constant/colors.dart';
import '../core/services/database_helper.dart';

class InAppPurchaseProvider extends ChangeNotifier {
  InAppPurchaseProvider() {
    debugPrint('InAppPurchaseProvider initialized');
    fetchOfferings();
    checkSubscriptionStatus();
  }
  final String entitlementID = "premium";
  bool isSubscribed = false;
  bool isTrial = false;
  Offering? offering;
  bool isLoading = false;
  List<Package>? availablePackages;
  bool? _canPost;
  DateTime? _nextRefillDate;

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

  Package? get weeklyPackage {
    final package =
        availablePackages
            ?.where((pkg) => pkg.packageType == PackageType.weekly)
            .toList()
            .cast<Package?>()
            .firstOrNull;
    debugPrint('Weekly package: ${package?.storeProduct.identifier}');
    return package;
  }

  Package? get monthlyPackage {
    final package =
        availablePackages
            ?.where((pkg) => pkg.packageType == PackageType.monthly)
            .toList()
            .cast<Package?>()
            .firstOrNull;
    debugPrint('Monthly package: ${package?.storeProduct.identifier}');
    return package;
  }

  Package? get yearlyPackage {
    final package =
        availablePackages
            ?.where((pkg) => pkg.packageType == PackageType.annual)
            .toList()
            .cast<Package?>()
            .firstOrNull;
    debugPrint('Yearly package: ${package?.storeProduct.identifier}');
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
      await Purchases.purchasePackage(package);
      debugPrint('Purchase successful.');
      // The sync will happen inside checkSubscriptionStatus
      await checkSubscriptionStatus();
      return isSubscribed;
    } on PlatformException catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  Future<void> checkSubscriptionStatus() async {
    debugPrint('Checking subscription status...');
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      debugPrint("Customer Info: $customerInfo");

      final entitlement = customerInfo.entitlements.all[entitlementID];
      if (entitlement != null && entitlement.isActive == true) {
        isSubscribed = true;
        isTrial = entitlement.periodType == PeriodType.trial;
        if (entitlement.expirationDate != null) {
          _nextRefillDate = DateTime.tryParse(entitlement.expirationDate!);
        }
        debugPrint(
          "Subscription is active. Trial: $isTrial. Next refill: $_nextRefillDate",
        );

        // --- NEW: Automated Credit Sync ---
        await syncCredits(customerInfo);
      } else {
        isSubscribed = false;
        isTrial = false;
        debugPrint("No active subscription found.");
      }
    } catch (e) {
      debugPrint("Error checking subscription status: $e");
    }
    notifyListeners();
  }

  Future<void> syncCredits(CustomerInfo customerInfo) async {
    final entitlement = customerInfo.entitlements.all[entitlementID];
    if (entitlement == null || entitlement.isActive != true) return;

    final latestPurchaseDate = entitlement.latestPurchaseDate;
    final productId = entitlement.productIdentifier;

    final context = Get.context;
    if (context == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;

    // If we already processed this purchase date, skip
    if (user.lastCreditSync == latestPurchaseDate) {
      debugPrint(
        "✅ Credits for cycle $latestPurchaseDate already granted. Skipping.",
      );
      return;
    }

    debugPrint(
      "🔄 New billing cycle detected: $latestPurchaseDate. Granting credits...",
    );

    // Determine credits to add based on product ID
    int creditsToAdd = 0;
    // We match against known product types or identifiers
    // Based on subscription_page.dart: Weekly -> 1, Monthly -> 10, Yearly -> 55
    if (productId.contains('weekly')) {
      creditsToAdd = 1;
    } else if (productId.contains('monthly')) {
      creditsToAdd = 10;
    } else if (productId.contains('yearly') || productId.contains('annual')) {
      creditsToAdd = 55;
    } else {
      // Fallback if naming convention differs, check the available packages
      if (weeklyPackage?.storeProduct.identifier == productId)
        creditsToAdd = 1;
      else if (monthlyPackage?.storeProduct.identifier == productId)
        creditsToAdd = 10;
      else if (yearlyPackage?.storeProduct.identifier == productId)
        creditsToAdd = 55;
    }

    if (creditsToAdd == 0) {
      debugPrint(
        "⚠️ Could not determine credit amount for product: $productId",
      );
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final currentCredits = snapshot.data()?['credits'] ?? 0;
        final updatedCredits = (currentCredits as int) + creditsToAdd;

        transaction.update(docRef, {
          'credits': updatedCredits,
          'lastCreditSync': latestPurchaseDate,
        });
      });

      // Update local model
      userProvider.user?.credits += creditsToAdd;
      userProvider.user?.lastCreditSync = latestPurchaseDate;
      userProvider.notifyListeners();

      // Removed Get.dialog from here so that the UI can handle routing cleanly
      // We will let the subscription page trigger the dialog after popping itself

      debugPrint(
        "✅ Automated Sync: Added $creditsToAdd credits for cycle $latestPurchaseDate",
      );
    } catch (e) {
      debugPrint("❌ Error during host sync credits: $e");
    }
  }

  Future<void> restorePurchases() async {
    debugPrint('Restoring purchases...');
    try {
      CustomerInfo restoredInfo = await Purchases.restorePurchases();
      final entitlement = restoredInfo.entitlements.all[entitlementID];

      if (entitlement != null && entitlement.isActive == true) {
        isSubscribed = true;
        debugPrint("Restore successful. Subscription active.");
        Get.snackbar(
          'successful'.tr,
          'purchaseRestoreSuccessfully'.tr,
          colorText: AppColors.textColor,
        );
      } else {
        isSubscribed = false;
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
    notifyListeners();
  }

  Future<void> check() async {
    debugPrint('can post called');
    // Allow posting if user has credits, regardless of active subscription status
    final result = await PostLimitChecker().canUserNormalPost();
    _canPost = result;

    notifyListeners();
  }

  // Deprecated: use automated sync instead
  Future<void> resetCurrentUserCreditsTo(
    int creditsToAdd,
    BuildContext context,
  ) async {
    // Keep for backward compatibility but redirect to a no-op if possible
    // Actually, let's keep it as is for now to avoid breaking UI before cleanup
    syncCredits(await Purchases.getCustomerInfo());
  }

  Future<bool> deductCredit() async {
    try {
      final userid = FirebaseAuth.instance.currentUser?.uid;
      if (userid == null) return false;

      final docRef = FirebaseFirestore.instance.collection('users').doc(userid);

      return await FirebaseFirestore.instance.runTransaction((
        transaction,
      ) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return false;

        final currentCredits = snapshot.data()?['credits'] ?? 0;
        if (currentCredits is int && currentCredits > 0) {
          transaction.update(docRef, {'credits': currentCredits - 1});

          // Update local provider if possible
          final context = Get.context;
          if (context != null) {
            final userProv = Provider.of<UserProvider>(context, listen: false);
            if (userProv.user != null) {
              userProv.user!.credits -= 1;
              userProv.notifyListeners();
            }
          }

          return true;
        }
        return false;
      });
    } catch (e) {
      debugPrint('❌ Error deducting credit: $e');
      return false;
    }
  }

  Future<void> deductOneCreditFromCurrentUser() async {
    await deductCredit();
  }
}
