import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:sapere/core/services/local_storage_service.dart';
import 'package:sapere/providers/subscription_provider.dart';
import 'package:sapere/core/utils/navigation_utils.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  void _checkInitialConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final provider = Provider.of<InAppPurchaseProvider>(context, listen: false);
    provider.checkSubscriptionStatus();
    await Future.delayed(const Duration(seconds: 4));

    print('Connectivity Status: $connectivityResult');

    if (connectivityResult.isNotEmpty &&
        connectivityResult.first != ConnectivityResult.none) {
      bool isFirst = await LocalStorage().getIsFirstTime() ?? true;

      if (isFirst) {
        // We always show language selection before onboarding per user request
        Navigator.pushReplacementNamed(context, Routes.initLanguageSelectPage);
      } else {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          Navigator.pushReplacementNamed(context, Routes.signInScreen);
        } else {
          final subProvider = Provider.of<InAppPurchaseProvider>(
            context,
            listen: false,
          );
          await subProvider.checkSubscriptionStatus();
          if (!mounted) return;
          redirectToCorrectScreen(context, subProvider.isSubscribed);
        }
      }
    } else {
      Navigator.pushReplacementNamed(context, Routes.connectivityCheckerScreen);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Image.asset("assets/splash.gif", fit: BoxFit.cover),
      ),
    );
  }
}

class ConnectivityCheckerScreen extends StatefulWidget {
  const ConnectivityCheckerScreen({super.key});

  @override
  State<ConnectivityCheckerScreen> createState() =>
      _ConnectivityCheckerScreenState();
}

class _ConnectivityCheckerScreenState extends State<ConnectivityCheckerScreen> {
  void _navigateToSplashScreen() {
    print('Navigating to splash screen');
    Navigator.pushReplacementNamed(context, Routes.splashScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppImagesUrls.noInternet),
          const SizedBox(height: 50),
          IconButton(
            onPressed: _navigateToSplashScreen,
            icon: Icon(Icons.refresh, size: 50, color: AppColors.primaryColor),
          ),
        ],
      ),
    );
  }
}
