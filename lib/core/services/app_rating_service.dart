import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sapere/widgets/dailogs/internal_rating_dialog.dart';

class AppRatingService {
  static final AppRatingService _instance = AppRatingService._internal();

  static AppRatingService get instance => _instance;

  AppRatingService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  static const String _hasRatedKey = 'hasRatedAppInternal';
  bool _hasRatedApp = false;
  bool _hasDismissedRatingForSession = false;

  final String appleAppId = '6746458440';
  final String googlePlayPackageName = 'com.victor.sapere';

  // Platform-specific store URLs
  String get _playStoreUrl =>
      'https://play.google.com/store/apps/details?id=$googlePlayPackageName';

  String get _appStoreUrl => 'https://apps.apple.com/app/id$appleAppId';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _hasRatedApp = prefs.getBool(_hasRatedKey) ?? false;
  }

  bool get hasRatedApp => _hasRatedApp;

  Future<void> setHasRatedApp(bool value) async {
    _hasRatedApp = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRatedKey, value);
  }

  void dismissForSession() {
    _hasDismissedRatingForSession = true;
  }

  Future<void> maybeShowRatingDialog(BuildContext context) async {
    if (_hasRatedApp || _hasDismissedRatingForSession) {
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const InternalRatingDialog();
      },
    );
  }

  /// First tries the native review popup (quiet, no guarantee).
  /// Then opens the store listing so user can leave a public review.
  Future<void> triggerNativeReview() async {
    try {
      // 1️⃣ Try native in-app review (system popup, best effort)
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (e) {
      debugPrint('InAppReview.requestReview failed: $e');
    }

    // 2️⃣ Always open store listing so user can leave a public review
    await openStoreListing();
  }

  /// Opens the Google Play Store (Android) or App Store (iOS) listing.
  Future<void> openStoreListing() async {
    final storeUrl = Platform.isIOS ? _appStoreUrl : _playStoreUrl;
    final uri = Uri.parse(storeUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('⚠️ Cannot launch store URL: $storeUrl');
      }
    } catch (e) {
      debugPrint('❌ Error opening store listing: $e');
    }
  }
}
