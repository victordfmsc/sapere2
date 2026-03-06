import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/models/cover_categories.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constant/firestore_collection.dart';
import '../../../../widgets/sapere_image.dart';

class CustomGallery extends StatefulWidget {
  final Function(String) onImageSelected;

  const CustomGallery({super.key, required this.onImageSelected});

  @override
  State<CustomGallery> createState() => _CustomGalleryState();
}

class _CustomGalleryState extends State<CustomGallery> {
  List<CoverCategoryModel> categories = [];
  List<CoverImage> imageList = [];
  String? selectedCategoryId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final snap =
        await FirebaseFirestore.instance.collection(coversCollection).get();

    categories =
        snap.docs.map((doc) => CoverCategoryModel.fromFirestore(doc)).toList();

    if (categories.isNotEmpty) {
      selectedCategoryId = categories.first.docId;
      await fetchImagesForCategory(selectedCategoryId!);
    }

    setState(() {});
  }

  Future<void> fetchImagesForCategory(String categoryDocId) async {
    setState(() {
      isLoading = true;
      imageList = [];
    });

    final snap =
        await FirebaseFirestore.instance
            .collection(coversCollection)
            .doc(categoryDocId)
            .collection('covers')
            .orderBy('uploadedAt', descending: true)
            .get();

    imageList =
        snap.docs
            .map(
              (doc) => CoverImage(
                docId: doc.id,
                imageUrl: doc['imageUrl'] as String,
              ),
            )
            .toList();

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blackColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'selectBukBukCover'.tr,
            style: TextStyle(
              fontSize: 20.sp,
              color: AppColors.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          _buildCategoryChips(),
          SizedBox(height: 10.h),
          isLoading
              ? const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
              : Expanded(child: _buildCoverGrid()),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            categories.map((category) {
              final isSelected = category.docId == selectedCategoryId;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: ChoiceChip(
                  label: Text(
                    category.names['en_US'] ?? 'Unnamed',
                    style: TextStyle(
                      color:
                          isSelected
                              ? AppColors.blackColor
                              : AppColors.textColor,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.whiteColor,
                  backgroundColor: AppColors.blackColor,
                  onSelected: (_) async {
                    setState(() {
                      selectedCategoryId = category.docId;
                    });
                    await fetchImagesForCategory(category.docId);
                  },
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCoverGrid() {
    return GridView.builder(
      itemCount: imageList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        final image = imageList[index];
        return GestureDetector(
          onTap: () {
            widget.onImageSelected(image.imageUrl);
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SapereImage(imageUrl: image.imageUrl, fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }
}
