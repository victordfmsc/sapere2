import 'dart:convert';
import 'dart:math';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:sapere/widgets/primary_button.dart';
import 'package:sapere/widgets/primarytextfield.dart';
import 'package:crypto/crypto.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../providers/user_provider.dart';

class AccountDeletion extends StatefulWidget {
  const AccountDeletion({super.key});

  @override
  State<AccountDeletion> createState() => _AccountDeletionState();
}

class _AccountDeletionState extends State<AccountDeletion> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final TextTheme appTextStyle = Theme.of(context).textTheme;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'accountDeletion'.tr,
          style: appTextStyle.bodyLarge!.copyWith(
            fontSize: 25.sp,
            color: AppColors.textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Center(
                child: Icon(Icons.delete, color: AppColors.textColor, size: 60),
              ),
              SizedBox(height: 20.h),
              Center(
                child: Text(
                  'accountDeletionWarning'.tr,
                  style: appTextStyle.bodyLarge!.copyWith(
                    fontSize: 22.sp,
                    color: Colors.red,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Center(
                child: Text(
                  'areYouSureDelete'.tr,
                  style: appTextStyle.bodyLarge!.copyWith(
                    fontSize: 18.sp,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              if (user?.signIn == 'email') ...[
                SizedBox(height: 40.h),
                PrimaryTextFormField(
                  hintText: 'password'.tr,
                  controller: controller,
                  labelText: 'password'.tr,
                ),
                SizedBox(height: 40.h),
              ],
              PrimaryButton(
                onTap: () {
                  if (controller.text.isEmpty && user?.signIn == 'email') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('validatorPassword'.tr)),
                    );
                    return;
                  }
                  deleteAccount(context, controller, user!.signIn);
                },
                text: 'deleteAccount'.tr,
                textColor: Colors.white,
                fontSize: 20.sp,
                bgColor: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> deleteAccount(
    BuildContext context,
    TextEditingController passC,
    String type,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'PleaseWait'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text('deletionInProgress'.tr),
              ],
            ),
          ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser!;
      if (type == 'email') {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: passC.text,
        );
        await user.reauthenticateWithCredential(credential);
      } else if (type == 'Apple') {
        final credential = await signInApple();
        await user.reauthenticateWithCredential(credential);
      } else {
        final credential = await signInGoogle();
        await user.reauthenticateWithCredential(credential!);
      }

      Navigator.pop(context); // close loading
      await deleteAllData(context, type);
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Reauth failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('invalidPassword'.tr)));
    }
  }

  Future<void> deleteAllData(BuildContext context, String type) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;
    final auth = FirebaseAuth.instance;

    try {
      final userDocs =
          await firestore
              .collection('Users')
              .where('uId', isEqualTo: uid)
              .get();
      for (var doc in userDocs.docs) {
        await doc.reference.delete();
      }

      final postDocs =
          await firestore
              .collection('Posts')
              .where('uId', isEqualTo: uid)
              .get();
      for (var doc in postDocs.docs) {
        await doc.reference.delete();
      }

      final ListResult result = await storage.ref(uid).listAll();
      for (final Reference ref in result.items) {
        await ref.delete();
      }

      await auth.currentUser?.delete();
      await auth.signOut();
      await GoogleSignIn().signOut();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('accountAndDataDeleted'.tr)));
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.signInScreen,
        (route) => false,
      );
    } catch (e) {
      debugPrint('Deletion error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('errorDeletingUser'.tr)));
    }
  }
}

String generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
}

String sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

Future<AuthCredential?> signInGoogle() async {
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
  final FirebaseAuth auth = FirebaseAuth.instance;

  try {
    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    UserCredential userCredential = await auth.signInWithCredential(credential);

    return userCredential.credential;
  } catch (error) {
    print('Google sign-in error: $error');
    return null;
  }
}

Future<OAuthCredential> signInApple() async {
  final rawNonce = generateNonce();
  final nonce = sha256ofString(rawNonce);

  final appleCredential = await SignInWithApple.getAppleIDCredential(
    scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
    nonce: nonce,
  );

  final oauthCredential = OAuthProvider(
    'apple.com',
  ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

  return oauthCredential;
}
