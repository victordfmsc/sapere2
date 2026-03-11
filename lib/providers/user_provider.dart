import 'dart:io';
import 'package:sapere/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../core/constant/firestore_collection.dart';

class UserProvider with ChangeNotifier {
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get user => _userModel;
  bool get isLoading => _isLoading;
  String? get currentAuthUid => FirebaseAuth.instance.currentUser?.uid;
  File? _pickedImage;
  File? get pickedImage => _pickedImage;

  int currentDiaries = 0;
  int numberOfBooks = 0;
  double progress = 0.0;
  int progressPercentage = 0;
  int diariesPerBook = 40;
  void setPickedImage(File? image) {
    _pickedImage = image;
    notifyListeners();
  }

  Future<void> fetchUserData() async {
    if (currentAuthUid == null) return;
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection(firebaseUserCollection)
              .doc(currentAuthUid!)
              .get();
      if (snapshot.exists) {
        _userModel = UserModel.fromMap(snapshot.data()!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> updateUser({
    required UserModel userModel,
    required BuildContext context,
    File? pickedImage,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? imageUrl = userModel.profileImage;

      if (pickedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profileImages')
            .child('${userModel.uId}.jpg');
        await storageRef.putFile(pickedImage);
        imageUrl = await storageRef.getDownloadURL();
      }

      final updatedData = userModel.copyWith(profileImage: imageUrl);
      await FirebaseFirestore.instance
          .collection(firebaseUserCollection)
          .doc(updatedData.uId)
          .set(updatedData.toMap(), SetOptions(merge: true));

      _userModel = updatedData;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error updating user: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateFCMToken() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final fcm = FirebaseMessaging.instance;
      final token = await fcm.getToken();
      final docRef = FirebaseFirestore.instance
          .collection(firebaseUserCollection)
          .doc(uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          transaction.update(docRef, {'fcmToken': token});
        } else {
          transaction.set(docRef, {'fcmToken': token});
        }
      });
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }
}
