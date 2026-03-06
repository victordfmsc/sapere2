import 'package:sapere/core/constant/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentWidget extends StatelessWidget {
  final String username;
  final String timestamp;
  final String comment;
  final String image;

  const CommentWidget({
    super.key,
    required this.username,
    required this.timestamp,
    required this.comment,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    DateTime parsedTimestamp = DateTime.parse(timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: image.toString(),
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.person),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: Get.width * 0.4,
                      child: Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor),
                      ),
                    ),
                    SizedBox(width: 10.w),

                    Text(
                      timeago.format(parsedTimestamp),
                      style: TextStyle(
                        color: AppColors.textColor,
                      ),
                    ), // Text(
                    //   DateFormat('dd-MM-yyyy HH:mm')
                    //       .format(DateTime.parse(timestamp)),
                    //   style: TextStyle(
                    //     color: Colors.grey[600],
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  comment,
                  style: TextStyle(fontSize: 16, color: AppColors.textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
