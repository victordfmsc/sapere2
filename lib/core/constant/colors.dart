import 'package:flutter/material.dart';

class AppColors {
  // static Color primaryColor = const Color(0xFFB54A3E);
  static Color primaryColor = const Color(0xFF262F3E);
  static Color kGrey = const Color(0xff848FAC);
  // static Color textColor = const Color(0xffB0B0B0);
  // static Color textColor = const Color(0xffD4AF37);
  static Color textColor = const Color(0xffF1CC89);
  static Color textColorSecondary = const Color(0xffA7C957);
  static Color kBackgroundBlackColor = const Color(0XFF000000);
  static Color kBackgroundWhiteColor = const Color.fromARGB(207, 233, 224, 224);
  static Color kLightBackground = const Color(0XFFDFE8F6);
  static Color secondaryColor = const Color(0xFFF6EFED);
  static Color splashColor = const Color(0XFFFCFCFB);
  static Color whiteColor = const Color(0xFFFFFFFF);
  static Color blackColor = const Color(0xFF000000);
  static Color kDeepBlack = const Color(0xFF080808); // Deeper, richer black
  static Color blackColor50 = const Color(0xFF28282B);
  static Color greyColor = const Color(0xFFE5E5E5);
  // static Color hintTextColor = const Color(0xFF9E9E9E);
  static Color hintTextColor = const Color(0xffB0B0B0);
  static Color halfWhiteColor = const Color(0xFFFAFAFA);
  static Color whiteLightColor = const Color(0xFFEFEFEF);
  static Color lightGrey12Color = const Color(0XFFEEEEEE);
  static Color kSamiOrange = const Color(0XFFFF1F2C);
  // static Color lightBlackColor = const Color(0xFF212121);
  static Color lightBlackColor = const Color(0xffB0B0B0);
  static Color kFillColor = const Color(0XFFF9F8F8);
  static Color lightGreyColor = const Color(0xFFEEEEEE);
  static Color orange = const Color(0xffFF9C27);

  // Premium Gradients
  static List<Color> kGoldGradient = [
    const Color(0xFFD4AF37),
    const Color(0xFFF1CC89),
    const Color(0xFFD4AF37),
  ];

  static List<Color> kPremiumDarkGradient = [
    const Color(0xFF1A1B1E),
    const Color(0xFF000000),
  ];

  static LinearGradient get premiumGoldGradient => LinearGradient(
    colors: kGoldGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<Color> kLinearGradient = [
    Color(0xffB54E3A),
    Color(0xffBC67F2),
    Color(0xffACF6AF),
    Color(0xffF95549),
  ];

  // Glassmorphism constants
  static Color kGlassBackground = Colors.white.withOpacity(0.08);
  static Color kGlassBorder = Colors.white.withOpacity(0.12);
}
