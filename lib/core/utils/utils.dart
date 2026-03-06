import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'package:url_launcher/url_launcher.dart';

import '../constant/colors.dart';

double scrWidth(c) => MediaQuery.of(c).size.width;
double scrHeight(c) => MediaQuery.of(c).size.height;

Widget kWidth(double w) => SizedBox(width: w);
Widget kHeight(double h) => SizedBox(height: h);

Widget kWidthHeight(w, h) => SizedBox(width: w, height: h);

void redirectToAppStore() async {
  String platformUrl;

  if (Platform.isIOS) {
    platformUrl =
    'https://apps.apple.com/us/app/daiary-your-book-with-ai/id6475233413';
  } else {
    platformUrl =
    'https://play.google.com/store/apps/details?id=com.victor.dairy';
  }

  if (platformUrl.isNotEmpty) {
    final uri = Uri.parse(platformUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch the URL');
    }
  }
}


Future<void> launchMailto() async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: 'victordfmsc@gmail.com',
    query: Uri.encodeFull('subject=App Feedback&body=Bukbuk app'),
  );

  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri, mode: LaunchMode.externalApplication);
  } else {
    print('❌ Could not launch email app');
    Get.snackbar('Error', 'No email app found to handle the request.',colorText: AppColors.textColor);
  }
}


///Hive keys
///
class AppHiveBoxKeys {

}
