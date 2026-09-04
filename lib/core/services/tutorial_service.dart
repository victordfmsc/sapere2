import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:sapere/core/services/local_storage_service.dart';

class TutorialService {
  final BuildContext context;
  final List<TargetFocus> targets;
  final String tutorialKey;
  final VoidCallback? onComplete;

  TutorialCoachMark? _tutorialCoachMark;

  TutorialService({
    required this.context,
    required this.targets,
    required this.tutorialKey,
    this.onComplete,
  });

  Future<void> showIfNeeded() async {
    final localStorage = LocalStorage();
    final shown = await localStorage.getData(key: tutorialKey) ?? 'false';

    if (shown == 'false') {
      _tutorialCoachMark = TutorialCoachMark(
        targets: targets,
        colorShadow: Colors.black,
        hideSkip: false,
        showSkipInLastTarget: false,
        paddingFocus: 10,
        opacityShadow: 0.6,
        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        onFinish: () {
          onComplete?.call();
        },
        onSkip: () {
          onComplete?.call();
          return true;
        },
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (context.mounted) {
        _tutorialCoachMark?.show(context: context);
      }

      // Save as shown
      await localStorage.setData(key: tutorialKey, value: 'true');
    } else {
      onComplete?.call();
    }
  }
}
