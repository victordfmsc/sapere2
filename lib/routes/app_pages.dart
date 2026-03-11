import 'package:sapere/langauges/init_lang_select_page.dart';
import 'package:sapere/langauges/lang_select_page.dart';
import 'package:sapere/models/post.dart';
import 'package:sapere/views/auth/forgot_page.dart';
import 'package:sapere/views/auth/signin_page.dart';
import 'package:sapere/views/auth/signup_page.dart';
import 'package:sapere/views/dashboard/drawer/account_deletion.dart';
import 'package:sapere/views/dashboard/drawer/profilePage/editprofile_page.dart';
import 'package:sapere/views/dashboard/drawer/profilePage/change_password.dart';
import 'package:sapere/views/dashboard/drawer/profilePage/profile_page.dart';
import 'package:sapere/views/dashboard/drawer/terms_condition_page.dart';
import 'package:sapere/views/dashboard/commuinty/quill_page.dart';
import 'package:sapere/views/dashboard/stream/add_sapere/add_sapere_page.dart';
import 'package:sapere/views/dashboard/stream/add_sapere/generate_sapere_page.dart';
import 'package:sapere/views/dashboard/stream/details_page/sapere_details.dart';
import 'package:sapere/views/dashboard/subscription/subscription_page.dart';
import 'package:sapere/views/landingPage/dashboard_page.dart';
import 'package:sapere/views/onboarding/intro_screen.dart';
import 'package:sapere/views/splash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../views/dashboard/subscription/free_trial_screen.dart';
import '../views/dashboard/stream/audio_player/audio_player.dart';

class Routes {
  static const String splashScreen = '/';
  static const String connectivityCheckerScreen = 'ConnectivityCheckerScreen';
  static const String onboardScreen = '/onboardScreen';
  static const String initLanguageSelectPage = '/initLanguageSelectPage';
  static const String signInScreen = '/signInScreen';
  static const String signUpScreen = '/signUpScreen';
  static const String forgotPasswordScreen = '/forgotPasswordScreen';
  static const String changePasswordScreen = '/changePasswordScreen';
  static const String dashboardScreen = '/DashboardScreen';
  static const String homeScreen = '/homeScreen';
  static const String addBukBukPage = '/addBukBukPage';
  static const String generateArticlePage = '/generateArticlePage';
  static const String quillPage = '/quillPage';
  static const String sapereDetails = '/sapereDetails';
  static const String profileScreen = '/profileScreen';
  static const String editProfileScreen = '/editProfileScreen';
  static const String changePasswordPage = '/changePasswordPage';
  static const String contactUsScreen = '/contactUsScreen';
  static const String termsConditionPage = '/termsConditionPage';
  static const String languageScreen = '/languageScreen';
  static const String accountDeletion = '/accountDeletion';
  static const String subscriptionPage = '/subscriptionPage';
  static const String longDescriptionScreen = '/longDescriptionScreen';
  static const String freeTrialScreen = '/freeTrialScreen';
  static const String audioPlayer = '/audioPlayer';
}

class AppPages {
  AppPages._();

  static const initialRoute = Routes.splashScreen;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splashScreen:
        return _buildAnimatedRoute(const SplashPage(), settings);

      case Routes.onboardScreen:
        return _buildAnimatedRoute(const OnBoardingScreen(), settings);

      case Routes.initLanguageSelectPage:
        return _buildAnimatedRoute(const InitLanguageSelectPage(), settings);

      case Routes.connectivityCheckerScreen:
        return _buildAnimatedRoute(const ConnectivityCheckerScreen(), settings);

      case Routes.signInScreen:
        return _buildAnimatedRoute(const SignInScreen(), settings);

      case Routes.freeTrialScreen:
        return _buildAnimatedRoute(const FreeTrialScreen(), settings);

      case Routes.forgotPasswordScreen:
        return _buildAnimatedRoute(const ForGetPasswordPage(), settings);

      case Routes.signUpScreen:
        return _buildAnimatedRoute(const SignUpScreen(), settings);

      case Routes.dashboardScreen:
        return _buildAnimatedRoute(const DashboardScreen(), settings);

      case Routes.profileScreen:
        return _buildAnimatedRoute(const ProfilePage(), settings);

      case Routes.editProfileScreen:
        return _buildAnimatedRoute(const EditProfilePage(), settings);

      case Routes.forgotPasswordScreen:
        return _buildAnimatedRoute(const ForGetPasswordPage(), settings);

      case Routes.changePasswordPage:
        return _buildAnimatedRoute(const ChangePasswordScreen(), settings);

      case Routes.languageScreen:
        return _buildAnimatedRoute(const LanguageSelectPage(), settings);

      case Routes.accountDeletion:
        return _buildAnimatedRoute(const AccountDeletion(), settings);

      case Routes.subscriptionPage:
        return _buildAnimatedRoute(const SubscriptionPage(), settings);

      case Routes.quillPage:
        return _buildAnimatedRoute(const QuillPage(), settings);

      case Routes.sapereDetails:
        return _buildAnimatedRoute(
          SapereDetails(post: settings.arguments as BukBukPost),
          settings,
        );

      case Routes.addBukBukPage:
        return _buildAnimatedRoute(const AddSaperePage(), settings);

      case Routes.generateArticlePage:
        return _buildAnimatedRoute(const GenerateArticlePage(), settings);

      case Routes.termsConditionPage:
        return _buildAnimatedRoute(TermsConditionPage(), settings);

      case Routes.audioPlayer:
        return _buildAnimatedRoute(
          AudioPlayerScreen(post: settings.arguments as BukBukPost),
          settings,
        );

      // case Routes.allCards:
      //   return _buildAnimatedRoute(
      //       AllCards(params: settings.arguments as CardDataParams), settings);
      //

      default:
        return _buildAnimatedRoute(
          Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildAnimatedRoute(
    Widget page,
    RouteSettings settings,
  ) {
    print("Navigating to: ${settings.name}");

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        print("PageBuilder called for ${settings.name}");
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (kDebugMode) {
          print("Transition started for ${settings.name}");
        }

        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        animation.addStatusListener((status) {
          print("Animation status for ${settings.name}: $status");
        });

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}
