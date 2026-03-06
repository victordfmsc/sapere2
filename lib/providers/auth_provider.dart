import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;
import 'package:sapere/core/constant/firestore_collection.dart';
import 'package:sapere/core/services/firebase_storage_service.dart';
import 'package:sapere/models/user_model.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:sapere/widgets/dailogs/email_verify.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constant/colors.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _firebaseUser;
  final bool _isEmailVerified = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _isChangeLoading = false;
  bool _isLoadingEmail = false;
  bool _isChecked = false;

  User? get firebaseUser => _firebaseUser;
  bool get isEmailVerified => _isEmailVerified;
  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get isAppleLoading => _isAppleLoading;
  bool get isChangeLoading => _isChangeLoading;
  bool get isLoadingEmail => _isLoadingEmail;
  bool get isChecked => _isChecked;

  set isChecked(bool value) {
    _isChecked = value;
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set isGoogleLoading(bool value) {
    _isGoogleLoading = value;
    notifyListeners();
  }

  set isAppleLoading(bool value) {
    _isAppleLoading = value;
    notifyListeners();
  }

  set isChangeLoading(bool value) {
    _isChangeLoading = value;
    notifyListeners();
  }

  set isLoadingEmail(bool value) {
    _isLoadingEmail = value;
    notifyListeners();
  }

  void toggleCheck(bool value) {
    _isChecked = value;
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required File file,
    required BuildContext context,
    required UserModel userModel,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String? profileImageUrl = await FirebaseStorageService()
          .uploadCoverImageToStorage(file: file, folderName: 'UserProfile');

      userModel.uId = userCredential.user!.uid;
      userModel.profileImage = profileImageUrl ?? '';

      await createUser(userModel: userModel);

      _isChecked = false;
      Navigator.pushReplacementNamed(context, Routes.signInScreen);
    } catch (e) {
      log('SignUp Error: $e');
      Get.snackbar(
        'signUpFailed'.tr,
        e.toString(),
        colorText: AppColors.textColor,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser({required UserModel userModel}) async {
    try {
      await FirebaseFirestore.instance
          .collection(firebaseUserCollection)
          .doc(userModel.uId)
          .set(userModel.toMap());
    } catch (e) {
      log('Error creating user: $e');
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          Navigator.pushReplacementNamed(context, Routes.dashboardScreen);
        } else {
          Get.dialog(
            EmailVerificationDialog(
              onTap: () async {
                await user.sendEmailVerification();
                Get.back();
                Get.snackbar(
                  'verificationSent'.tr,
                  'aNewVerification'.tr,
                  colorText: AppColors.textColor,
                );
              },
            ),
          );
        }
      }
    } catch (e) {
      log('SignIn Error: $e');
      Get.snackbar(
        'signINFailed'.tr,
        e.toString(),
        colorText: AppColors.textColor,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required BuildContext context,
  }) async {
    isChangeLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception("No user found.");
      }

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      Get.snackbar(
        'passwordChanged'.tr,
        'passwordHasChanged'.tr,
        colorText: AppColors.textColor,
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Get.snackbar('', e.message.toString(), colorText: AppColors.textColor);

      rethrow;
    } catch (e) {
      Get.snackbar('', e.toString(), colorText: AppColors.textColor);

      rethrow;
    } finally {
      isChangeLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendResetLink({
    required String email,
    required BuildContext context,
  }) async {
    isLoadingEmail = true;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'forgotPasswordText'.tr,
        'aPasswordResetLink'.tr,
        colorText: AppColors.textColor,
      );
    } catch (e) {
      log('Reset link error: $e');
      Get.snackbar(
        'Error',
        'Failed to send reset link. Please try again.',
        colorText: AppColors.textColor,
      );
      rethrow;
    } finally {
      isLoadingEmail = false;
      notifyListeners();
      Navigator.pop(context);
    }
  }

  Future<void> signOut(BuildContext context) async {
    isLoading = true;
    notifyListeners();
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
      _firebaseUser = null;
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.signInScreen,
        (route) => false,
      );
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    isGoogleLoading = true;
    notifyListeners();

    try {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();

      if (googleUser == null) {
        isGoogleLoading = false;
        notifyListeners();
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      _firebaseUser = userCredential.user;

      if (_firebaseUser != null) {
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          final userModel = UserModel(
            email: _firebaseUser!.email!,
            userName: _firebaseUser!.displayName ?? '',
            profileImage: _firebaseUser!.photoURL ?? '',
            dateOfBirth: '',
            gender: '',
            phone: '',
            address: '',
            uId: _firebaseUser!.uid,
            credits: 0,
            signIn: 'google',
            userType: 'normal',
          );
          await createUser(userModel: userModel);
        }
        Navigator.pushReplacementNamed(context, Routes.dashboardScreen);
      }
    } catch (e) {
      log('Google sign-in error: $e');
      rethrow;
    } finally {
      isGoogleLoading = false;
      notifyListeners();
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

  Future<void> signInWithApple(BuildContext context) async {
    isAppleLoading = true;
    notifyListeners();

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      _firebaseUser = userCredential.user;

      if (_firebaseUser != null) {
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          final userModel = UserModel(
            email: _firebaseUser!.email!,
            userName: _firebaseUser!.displayName ?? '',
            profileImage: _firebaseUser!.photoURL ?? '',
            dateOfBirth: '',
            gender: 'Gender',
            phone: '',
            address: '',
            uId: _firebaseUser!.uid,
            credits: 0,
            signIn: 'apple',
            userType: 'normal',
          );
          await createUser(userModel: userModel);
        }
        Navigator.pushReplacementNamed(context, Routes.dashboardScreen);
      }
    } on FirebaseAuthException catch (e) {
      log('Apple login error (Firebase): ${e.toString()}');
      rethrow;
    } catch (e) {
      log('Apple login error: ${e.toString()}');
      rethrow;
    } finally {
      isAppleLoading = false;
      notifyListeners();
    }
  }
}
