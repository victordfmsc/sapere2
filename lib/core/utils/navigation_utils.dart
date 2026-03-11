import 'package:flutter/material.dart';
import 'package:sapere/routes/app_pages.dart';

/// Centralized navigation logic to enforce a "Hard Paywall".
/// Redirects unsubscribed users to the FreeTrialScreen.
void redirectToCorrectScreen(BuildContext context, bool isSubscribed) {
  // 2026 Shift: Move to a "Rating-to-Unlock" model.
  // We no longer force the paywall on entry.
  Navigator.pushReplacementNamed(context, Routes.dashboardScreen);
}
