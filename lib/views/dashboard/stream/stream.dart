import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/const.dart';
import 'package:sapere/core/services/app_rating_service.dart';
import 'package:sapere/core/services/database_helper.dart';

import 'package:sapere/models/post.dart';
import 'package:sapere/providers/subscription_provider.dart';
import 'package:sapere/providers/user_provider.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:sapere/views/dashboard/drawer/drawer_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sapere/widgets/sapere_image.dart';
import 'components/sapere_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => StreamVm(context),
      child: Consumer<StreamVm>(
        builder: (context, vm, child) {
          // Sync with global locale if it changed
          final currentLocale = Get.locale?.toString() ?? 'en_US';
          if (vm.isLangLoaded && vm.languageCode != currentLocale) {
            Future.microtask(() => vm.loadLanguage(forceReload: true));
          }

          return AdvancedDrawer(
            backdrop: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(color: AppColors.kDeepBlack),
            ),
            controller: vm._advancedDrawerController,
            animationCurve: Curves.easeInOut,
            animationDuration: const Duration(milliseconds: 300),
            animateChildDecoration: true,
            rtlOpening: false,
            childDecoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            drawer: CustomDrawerScreen(version: vm.version),
            child: Consumer<InAppPurchaseProvider>(
              builder: (context, iapProvider, child) {
                return Scaffold(
                  backgroundColor: AppColors.kDeepBlack,
                  body: Stack(
                    children: [
                      // Main Content
                      CustomScrollView(
                        controller: vm.scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // 1. Hero Featured Story
                          if (vm.posts.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _buildFeaturedStory(
                                vm.posts.first,
                                context,
                              ),
                            ),
                          // 1.5 Subscription Banner
                          if (!iapProvider.isSubscribed &&
                              !AppRatingService.instance.hasRatedApp)
                            SliverToBoxAdapter(
                              child: _buildSubscriptionBanner(
                                iapProvider,
                                context,
                              ),
                            ),

                          // 3. Horizontal Story Rows
                          if (vm.posts.length > 0) ...[
                            SliverPadding(
                              padding: EdgeInsets.only(top: 20.h),
                              sliver: SliverToBoxAdapter(
                                child: _buildStoryRow(
                                  "trendingNow".tr,
                                  vm.posts.take(8).toList(),
                                  context,
                                ),
                              ),
                            ),
                            if (vm.posts.length > 8)
                              SliverToBoxAdapter(
                                child: _buildStoryRow(
                                  "popularOnSapere".tr,
                                  vm.posts.skip(8).toList(),
                                  context,
                                ),
                              ),
                          ],

                          // Loading/Empty States
                          if (vm.isLoading && vm.posts.isEmpty)
                            const SliverFillRemaining(
                              child: Center(child: BukBukLoadingWidget()),
                            ),

                          if (!vm.isLoading && vm.posts.isEmpty)
                            SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'noDataFound'.tr,
                                  style: TextStyle(color: AppColors.textColor),
                                ),
                              ),
                            ),

                          SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                        ],
                      ),

                      // 4. Overlaid Header
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildHomeHeader(vm, iapProvider, context),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeHeader(
    StreamVm vm,
    InAppPurchaseProvider iap,
    BuildContext context,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 10.w,
        right: 10.w,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: vm.handleMenuButtonPressed,
                    icon: Icon(Icons.menu, color: Colors.white, size: 28.sp),
                  ),
                  Text(
                    'S A P E R E',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textColor,
                      fontFamily: 'NotoSerifDisplay',
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Consumer<UserProvider>(
                      builder: (context, userProv, _) {
                        return userProv.user == null
                            ? const SizedBox()
                            : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8.w),
                                  child: Image.asset(
                                    'assets/coin.png',
                                    height: 20.h,
                                  ),
                                ),
                                Text(
                                  userProv.user!.credits.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 15.w),
                                CircleAvatar(
                                  radius: 18.r,
                                  backgroundColor: Colors.white24,
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          userProv.user?.profileImage ?? "",
                                      fit: BoxFit.cover,
                                      errorWidget:
                                          (context, url, error) => Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                      },
                    ),
                    SizedBox(width: 10.w),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 15.w, top: 4.h, bottom: 8.h),
              child: LanguageDropdown(
                languages: languageNames,
                selectedLanguage: vm.selectedLanguage,
                onChanged: (lang) {
                  vm.setLanguage(lang);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedStory(BukBukPost post, BuildContext context) {
    return GestureDetector(
      onTap:
          () => Navigator.pushNamed(
            context,
            Routes.sapereDetails,
            arguments: post,
          ),
      child: Container(
        height: 550.h,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            SapereImage(imageUrl: post.newCover.toString(), fit: BoxFit.cover),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                    AppColors.kDeepBlack.withOpacity(0.8),
                    AppColors.kDeepBlack,
                  ],
                  stops: const [0.4, 0.6, 0.8, 1.0],
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 40.h,
              left: 20.w,
              right: 20.w,
              child: Column(
                children: [
                  Text(
                    post.sapereName ?? "",
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 15.w,
                    runSpacing: 12.h,
                    children: [
                      _heroButton(
                        icon: Icons.play_arrow,
                        label: "play".tr,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              Routes.sapereDetails,
                              arguments: post,
                            ),
                        color: Colors.white,
                        textColor: Colors.black,
                        gradient: AppColors.kGoldGradient,
                      ),
                      _heroButton(
                        icon: Icons.info_outline,
                        label: "info".tr,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              Routes.sapereDetails,
                              arguments: post,
                            ),
                        color: Colors.white.withOpacity(0.1),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required Color textColor,
    List<Color>? gradient,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: gradient == null ? color : null,
          gradient:
              gradient != null
                  ? LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryRow(
    String title,
    List<BukBukPost> posts,
    BuildContext context,
  ) {
    if (posts.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20.w, bottom: 15.h, top: 25.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 20.w),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 14.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 20.w),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return SapereCard(
                imageUrl: post.newCover.toString(),
                title: post.sapereName ?? "",
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      Routes.sapereDetails,
                      arguments: post,
                    ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionBanner(
    InAppPurchaseProvider iap,
    BuildContext context,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD4AF37), // Gold
            Color(0xFF996515), // Deep Gold
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.stars_rounded, color: Colors.white, size: 40.sp),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'upgradeToPremium'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'upgradeToPremiumDesc'.tr,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed:
                () => Navigator.pushNamed(context, Routes.subscriptionPage),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 15.w),
            ),
            child: Text(
              'upgradeToPremiumBtn'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class StreamVm extends ChangeNotifier {
  StreamVm(BuildContext context) {
    getAppVersion();

    loadLanguage().then((_) {
      fetchPosts();

      scrollController.addListener(() {
        if (scrollController.position.pixels >=
                scrollController.position.maxScrollExtent - 200 &&
            !isLoading &&
            hasMore) {
          fetchPosts();
        }
      });
    });
  }

  final _advancedDrawerController = AdvancedDrawerController();
  final List<BukBukPost> posts = [];
  final ScrollController scrollController = ScrollController();
  final int _limit = 15;

  DocumentSnapshot? lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;

  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  void setIsLoading(bool value) {
    _isLoading = value;
  }

  void setHasMore(bool value) {
    _hasMore = value;
  }

  final db = DataBaseHelper();
  String languageCode = 'All';
  String selectedLanguage = 'All';
  bool isLangLoaded = false;

  Future<void> loadLanguage({bool forceReload = false}) async {
    final locale = Get.locale?.toString() ?? 'en_US';
    languageCode = locale;
    selectedLanguage = getLanguageName(locale);
    isLangLoaded = true;
    print('Selected language code is $languageCode, name: $selectedLanguage');

    if (forceReload) {
      lastDocument = null;
      posts.clear();
      _hasMore = true;
      fetchPosts();
    }
  }

  setLanguage(String v) {
    print('Selected language set to $v');
    selectedLanguage = v;

    // Update GetX locale so all .tr translations immediately use the new language
    if (v != 'All') {
      final localeCode = getLocaleFromLanguageName(v);
      final parts = localeCode.split('_');
      final newLocale = Locale(parts[0], parts.length > 1 ? parts[1] : '');
      Get.updateLocale(newLocale);
      languageCode = localeCode;
    }

    // We clear posts and reload
    lastDocument = null;
    posts.clear();
    _hasMore = true;
    notifyListeners();
    fetchPosts();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  String version = '';

  Future<void> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final versionName = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;
    version = 'v$versionName ($buildNumber)';
    notifyListeners();
  }

  Future<void> fetchPosts() async {
    if (!isLangLoaded) return;

    setIsLoading(true);
    print('Language filter (Posts): $selectedLanguage');

    Query<BukBukPost> query = db.postCollection
        .withConverter<BukBukPost>(
          fromFirestore: (doc, _) => BukBukPost.fromFirestore(doc),
          toFirestore: (post, _) => post.toMap(),
        )
        // Standard documentaries only, not reels
        .where('type', isNotEqualTo: 'preview')
        .orderBy(
          'type',
        ) // Requires composite index if sorting by another field, but standard index works if just filtering
        .orderBy('publishTime', descending: true)
        .limit(_limit);

    if (selectedLanguage != "All") {
      // Due to Firestore indexing rules with inequality filters (isNotEqualTo),
      // we might need to filter language client-side or use a composite index.
      // To avoid immediate composite index crashes, we filter the standard query.
      query = db.postCollection
          .withConverter<BukBukPost>(
            fromFirestore: (doc, _) => BukBukPost.fromFirestore(doc),
            toFirestore: (post, _) => post.toMap(),
          )
          .where('language', isEqualTo: selectedLanguage)
          // Note: cannot use unequal filter ('type', isNotEqualTo) on a different field than the range/order field in Datastore easily without index.
          // Since we want standard stories, and most are null or "standard", we can just fetch and filter client-side to be perfectly safe,
          // or rely on 'type' != 'preview'.
          .orderBy('publishTime', descending: true)
          .limit(_limit * 2); // Fetch more to account for client-side filtering
      print('Query filtered by language: $selectedLanguage');
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    try {
      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;

        final newPosts =
            snapshot.docs
                .map((doc) => doc.data())
                .whereType<BukBukPost>()
                .where(
                  (post) => post.type != 'preview',
                ) // Client side filter to be 100% safe
                .toList();

        posts.addAll(newPosts);
        if (snapshot.docs.length < (_limit)) _hasMore = false;
        notifyListeners();
      } else {
        setHasMore(false);
      }
    } catch (e) {
      print('❌ Error fetching posts: $e');
      Get.snackbar('Error', e.toString(), colorText: AppColors.textColor);
      setHasMore(false);
      setIsLoading(false);
    } finally {
      setIsLoading(false);
      notifyListeners();
    }
  }

  void handleMenuButtonPressed() {
    _advancedDrawerController.showDrawer();
  }

  Future<void> deletePost(String postId) async {
    try {
      await db.postCollection.doc(postId).delete();
      posts.removeWhere((p) => p.postId == postId);
      notifyListeners();
    } catch (e) {
      print('❌ Error deleting post: $e');
    }
  }

  /// Refreshes the post list after a delay to allow background tasks (like title generation) to finish.
  Future<void> refreshWithDelay({int seconds = 5}) async {
    print('⏱️ Starting delayed refresh ($seconds seconds)...');
    await Future.delayed(Duration(seconds: seconds));

    // Reset and refetch
    lastDocument = null;
    posts.clear();
    _hasMore = true;
    notifyListeners();
    await fetchPosts();
    print('✅ Delayed refresh complete.');
  }
}

class LanguageDropdown extends StatefulWidget {
  final List<String> languages;
  final void Function(String)? onChanged;
  final String selectedLanguage;

  const LanguageDropdown({
    super.key,
    required this.languages,
    required this.selectedLanguage,
    this.onChanged,
  });

  @override
  State<LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  late String currentLanguage;

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.selectedLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLanguage,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18.sp,
            color: Colors.white,
          ),
          elevation: 16,
          dropdownColor: AppColors.kDeepBlack,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                currentLanguage = newValue;
              });
              widget.onChanged?.call(newValue);
            }
          },
          items:
              widget.languages
                  .map<DropdownMenuItem<String>>(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Icon(
                            Icons.language,
                            size: 14.sp,
                            color: AppColors.kSamiOrange,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

class BukBukLoadingWidget extends StatelessWidget {
  const BukBukLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        shrinkWrap: true,
        itemCount: 4,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          mainAxisSpacing: 16.h,
          crossAxisSpacing: 12.w,
        ),
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 220.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                height: 14.h,
                width: 100.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 6.h),
              // Title line 2
              Container(
                height: 14.h,
                width: 60.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
