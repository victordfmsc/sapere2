import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import '../constant/colors.dart';

class FirebaseStorageService {
  final firebaseStorage = FirebaseStorage.instance;
  final firebaseAuth = FirebaseAuth.instance;
  Future<String?> uploadToStorage({
    required File? file,
    required String folderName,
    required String pdfId,
  }) async {
    try {
      final Reference ref = firebaseStorage.ref().child(
        'audios/${firebaseAuth.currentUser?.email}/${DateTime.now().microsecondsSinceEpoch}',
      );
      UploadTask task = ref.putFile(file!);
      TaskSnapshot snapshot = await task;
      String url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      Get.snackbar(
        'Storage Error',
        e.toString(),
        colorText: AppColors.textColor,
      );
      return "";
    }
  }

  Future<String?> uploadPublicPdf(String uid, File pdfFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final publicFolderRef = storageRef.child(
        'public//${firebaseAuth.currentUser?.email}/${DateTime.now().microsecondsSinceEpoch}.pdf',
      );

      final uploadTask = publicFolderRef.putFile(pdfFile);

      final snapshot = await uploadTask.whenComplete(() => null);

      final pdfUrl = await snapshot.ref.getDownloadURL();
      print('File uploaded to: $pdfUrl');

      return pdfUrl;
    } catch (e) {
      print('Failed to upload file: $e');
      return null;
    }
  }

  Future<String?> uploadCoverImageToStorage({
    required File? file,
    required String folderName,
  }) async {
    try {
      final Reference ref = firebaseStorage.ref().child(
        'profile/${firebaseAuth.currentUser?.email}/${DateTime.now().microsecondsSinceEpoch}',
      );
      UploadTask task = ref.putFile(file!);
      TaskSnapshot snapshot = await task;
      String url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      Get.snackbar(
        'Storage Error',
        e.toString(),
        colorText: AppColors.textColor,
      );
      return "";
    }
  }

  Future<String?> uploadCoverBytesToStorage({
    required Uint8List bytes,
    required String folderName,
  }) async {
    try {
      final Reference ref = firebaseStorage.ref().child(
        '$folderName/${firebaseAuth.currentUser?.email}/${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      UploadTask task = ref.putData(bytes);
      TaskSnapshot snapshot = await task;
      String url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      print('❌ Storage Error (Bytes): $e');
      return "";
    }
  }
}
