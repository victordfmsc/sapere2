import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sapere/core/constant/colors.dart';

class TrialTimelineWidget extends StatelessWidget {
  final int trialDays;
  const TrialTimelineWidget({super.key, this.trialDays = 7});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final reminderDay = (trialDays > 3) ? trialDays - 2 : 1;
    final dayReminder = now.add(Duration(days: reminderDay));
    final dayTrialEnd = now.add(Duration(days: trialDays));

    // Simple date formatting
    String formatDate(DateTime date) {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${months[date.month - 1]} ${date.day}";
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildTimelineStep(
            icon: Icons.star_rounded,
            title: 'today'.tr,
            desc: 'unlimitedAccess'.tr,
            isComplete: true,
            isFirst: true,
          ),
          _buildTimelineStep(
            icon: Icons.notifications_active_rounded,
            title: formatDate(dayReminder),
            desc: 'reminderSent'.tr,
            isComplete: false,
          ),
          _buildTimelineStep(
            icon: Icons.check_circle_rounded,
            title: formatDate(dayTrialEnd),
            desc: 'trialEnds'.tr,
            isComplete: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String desc,
    bool isComplete = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: isComplete ? AppColors.textColor : Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18.sp,
                  color: isComplete ? Colors.black : Colors.white30,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.w,
                    color:
                        isComplete
                            ? AppColors.textColor.withOpacity(0.3)
                            : Colors.white10,
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
