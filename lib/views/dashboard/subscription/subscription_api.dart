import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionApi {
  static Future<void> initPlatformState({required String key}) async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
    PurchasesConfiguration configuration = PurchasesConfiguration(key);

    await Purchases.configure(configuration);
  }

  /// Identifica al usuario en RevenueCat con su uid de Firebase para que el
  /// backend pueda gastar créditos con ese mismo customer id.
  static Future<void> logIn(String uid) async {
    try {
      final currentId = await Purchases.appUserID;
      if (currentId == uid) return;
      await Purchases.logIn(uid);
      debugPrint('RevenueCat logIn done for $uid');
    } catch (e) {
      debugPrint('RevenueCat logIn error: $e');
    }
  }

  static Future<void> logOut() async {
    try {
      if (await Purchases.isAnonymous) return;
      await Purchases.logOut();
      debugPrint('RevenueCat logOut done');
    } catch (e) {
      debugPrint('RevenueCat logOut error (ignored): $e');
    }
  }
}
