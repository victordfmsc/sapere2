import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/services/local_storage_service.dart';
import 'package:sapere/providers/auth_provider.dart';
import 'package:sapere/providers/sapere_provider.dart';
import 'package:sapere/providers/subscription_provider.dart';
import 'package:sapere/providers/user_provider.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:sapere/views/dashboard/stream/audio_player/audio_handler.dart';
import 'package:sapere/views/dashboard/subscription/subscription_api.dart';
import 'package:sapere/providers/history_provider.dart';
import 'package:sapere/providers/gamification_provider.dart';
import 'package:sapere/providers/learning_provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:provider/provider.dart';
import 'core/constant/strings.dart';
import 'firebase_options.dart';
import 'langauges/langauges.dart';
import 'package:get/get.dart';
// find . -type f -name "*.dart" -exec sed -i '' 's/sapere/sapere/g' {} +

late AudioPlayerHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.victor.sapere.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  String key =
      Platform.isAndroid
          ? 'goog_RdwMCJqPZwIhMuBZRPeVszstsPX'
          : 'appl_XplNhBGZacoyWBpXGDRxQrMeDHS';
  print(key.toString());
  await SubscriptionApi.init(apiKey: key);
  await SubscriptionApi.initPlatformState(key: key);

  String? local = await LocalStorage().getData(key: AppLocalKeys.localeKey);
  String? languageCode = await LocalStorage().getData(
    key: AppLocalKeys.languageCodeKey,
  );

  runApp(MyApp(languageCode: languageCode, local: local));
}

// firebaseCloudMessaging() async {
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
// }
//
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   print("Handling a background message: ${message.messageId}");
// }

class MyApp extends StatelessWidget {
  final String? languageCode, local;
  const MyApp({super.key, required this.languageCode, required this.local});

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    print('language code is $languageCode and the locale is $local');

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => InAppPurchaseProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => HistoryProvider()),
            ChangeNotifierProvider(create: (_) => GamificationProvider()),
            ChangeNotifierProvider(create: (_) => LearningProvider()),
            ChangeNotifierProvider(
              create: (_) => BukBukProvider(context)..init(context),
            ),
          ],
          child: GetMaterialApp(
            title: 'Sapere',
            translations: TransLanguage(),
            locale:
                (languageCode == null ||
                        languageCode!.isEmpty ||
                        local == null ||
                        local!.isEmpty)
                    ? Get.deviceLocale ?? const Locale('en', 'US')
                    : Locale(local!, languageCode!),
            debugShowCheckedModeBanner: false,
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: analytics),
            ],
            theme: ThemeData(
              scaffoldBackgroundColor: AppColors.blackColor,
              appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
              progressIndicatorTheme: ProgressIndicatorThemeData(
                color: AppColors.whiteColor,
              ),
              fontFamily: 'DMSans',
            ),
            initialRoute: AppPages.initialRoute,
            onGenerateRoute: AppPages.generateRoute,
            // home: const MainScreen(),
          ),
        );
      },
    );
  }
}

// pod setup && rm -rf Pods && rm Podfile.lock && rm -rf ~/Library/Developer/Xcode/DerivedData && Pod install && pod repo update && open Runner.xcworkspace
// open ios/Runner.xcworkspace
// open Runner.xcworkspace
//Joygram.kids@231
