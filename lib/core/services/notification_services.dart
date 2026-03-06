// import 'dart:io';
// import 'dart:math' as m;
//
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class NotificationServices {
//   FirebaseMessaging messaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin localNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//   Future<void> requestNotificationPermissionIOS() async {
//     debugPrint('ios setting');
//
//     var status = await Permission.notification.status;
//     if (!status.isGranted) {
//       debugPrint('Notification Permission request');
//
//       status = await Permission.notification.request();
//       if (status.isGranted) {
//         debugPrint("Notification Permission Granted");
//       } else if (status.isDenied) {
//         debugPrint("Notification Permission Denied");
//       } else if (status.isPermanentlyDenied) {
//         openAppSettings();
//
//         debugPrint("Notification Permission Denied permanently");
//       }
//     }
//   }
//
//   void requestNotificationPermission() async {
//     debugPrint('Notification Their');
//
//     if (Platform.isIOS) {
//       debugPrint('IOS>>>>>>>>>>>>>>>>');
//       requestNotificationPermissionIOS();
//     } else {
//       debugPrint('Permission request');
//       FirebaseMessaging messaging = FirebaseMessaging.instance;
//
//       NotificationSettings settings = await messaging.requestPermission(
//         alert: true,
//         announcement: false,
//         badge: true,
//         carPlay: false,
//         criticalAlert: false,
//         provisional: true,
//         sound: true,
//       );
//
//       if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//         print('User granted permission');
//       } else if (settings.authorizationStatus ==
//           AuthorizationStatus.provisional) {
//         print('User granted provisional permission');
//       } else {
//         print('User declined or has not accepted permission');
//       }
//     }
//   }
//
//   // Future<String> isTokenRefresh() async {
//   //   String newToken = '';
//   //   messaging.onTokenRefresh.listen((event) async {
//   //     newToken = event;
//   //     var box = Hive.box('userBox');
//   //     box.put('DeviceToken', newToken);
//   //     box.put('TokenTimestamp', DateTime.now().millisecondsSinceEpoch);
//   //     log('Token refreshed: $newToken');
//   //   }).asFuture(); // Be careful with this, it might not work as expected if onTokenRefresh doesn't emit immediately
//   //
//   //   // Return the new or existing token
//   //   newToken = await Hive.box('userBox').get('DeviceToken').toString();
//   //   return newToken;
//   // }
//
//   void firebaseInit(BuildContext context) {
//     FirebaseMessaging.onMessage.listen((messages) {
//       print(messages.notification!.title.toString());
//       if (Platform.isIOS) {
//         print('IOS NOTIFICATION>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
//         foregroundMessage();
//       }
//       if (Platform.isAndroid) {
//         print('Android NOTIFICATION>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
//
//         initNotification(context: context, message: messages);
//         showNotification(messages);
//       }
//     });
//   }
//
//   Future<void> initNotification(
//       {required BuildContext context, required RemoteMessage message}) async {
//     //AndroidInitializationSettings
//     AndroidInitializationSettings initializationSettingsAndroid =
//         const AndroidInitializationSettings('@mipmap/ic_launcher');
//
// //initializationSettingsIOS
//     var initializationSettingsIOS = const DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//
//     var initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     );
//     await localNotificationsPlugin.initialize(initializationSettings,
//         onDidReceiveNotificationResponse:
//             (NotificationResponse notificationResponse) async {
//       handleMessage(context, message);
//     });
//   }
//
//   // function to show visible notification when app is active
//   Future<void> showNotification(RemoteMessage message) async {
//     int id = m.Random.secure().nextInt(10000000);
//     AndroidNotificationDetails androidNotificationDetails =
//         const AndroidNotificationDetails(
//       'HighImportanceNotification',
//       "HighImportanceNotification name",
//       channelDescription: 'your channel description',
//       importance: Importance.max,
//       priority: Priority.high,
//       playSound: true,
//       ticker: 'ticker',
//       // sound: channel.sound
//       //     sound: RawResourceAndroidNotificationSound('jetsons_doorbell')
//       //  icon: largeIconPath
//     );
//
//     const DarwinNotificationDetails darwinNotificationDetails =
//         DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );
//
//     NotificationDetails notificationDetails = NotificationDetails(
//       android: androidNotificationDetails,
//       iOS: darwinNotificationDetails,
//     );
//
//     await localNotificationsPlugin.show(
//       id,
//       message.notification!.title.toString(),
//       message.notification!.body.toString(),
//       notificationDetails,
//     );
//   }
//
// //handle tap on notification when app is in background or terminated
//   Future<void> setupInteractMessage(BuildContext context) async {
//     // when app is terminated
//     RemoteMessage? initialMessage =
//         await FirebaseMessaging.instance.getInitialMessage();
//
//     if (initialMessage != null) {
//       handleMessage(context, initialMessage);
//     }
//
//     //when app ins background but app is open
//     FirebaseMessaging.onMessageOpenedApp.listen((event) {
//       handleMessage(context, event);
//     });
//   }
//
//   void handleMessage(BuildContext context, RemoteMessage message) {
//     print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.tap on notification');
//     print(message.toString());
//     // Navigator.push(navigatorKey.currentState!.context,
//     //     MaterialPageRoute(builder: (context) => const LoginScreen()));
//
//     print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.');
//   }
//
//   Future foregroundMessage() async {
//     print('IOS system');
//     await FirebaseMessaging.instance
//         .setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//   }
// }
