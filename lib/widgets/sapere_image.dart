import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SapereImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SapereImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the URL is a local asset or a network URL
    final bool isAsset = imageUrl.startsWith('assets/');

    if (isAsset) {
      return Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white24),
            ),
          );
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: 400, // Optimize memory consumption and decoding latency
      placeholder:
          (context, url) => Skeletonizer(
            child: Container(width: width, height: height, color: Colors.black),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white24),
            ),
          ),
    );
  }
}
