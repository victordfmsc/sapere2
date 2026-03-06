import 'package:sapere/core/constant/colors.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

import '../learning/learning_center_tab.dart';

class CommunityScreen extends StatefulWidget {
  final bool showBookmarked;

  const CommunityScreen({super.key, required this.showBookmarked});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logEvent(
      name: 'screen_view',
      parameters: {'screen_name': 'Social Screen', 'user_id': ''},
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mi Aprendizaje",
          style: TextStyle(color: AppColors.textColor),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: const LearningCenterTab(),
    );
  }
}
