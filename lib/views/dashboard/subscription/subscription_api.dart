// ignore_for_file: deprecated_member_use

import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionApi {
  static Future init({required String apiKey}) async {
    await Purchases.setDebugLogsEnabled(true);
    await Purchases.setup(apiKey);
    print('init done');
  }

  static Future<void> initPlatformState({required String key}) async {
    PurchasesConfiguration configuration = PurchasesConfiguration(key);

    await Purchases.configure(configuration);
  }
}
