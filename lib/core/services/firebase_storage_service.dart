import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constant/colors.dart';

/// Subidas a Storage. Las carpetas van por uid (con el email como segmento de
/// ruta, listar el bucket exponía el padrón de usuarios) y cada subida lleva un
/// contentType explícito, que storage.rules exige: image/*, audio/* o PDF.
class FirebaseStorageService {
  final firebaseStorage = FirebaseStorage.instance;
  final firebaseAuth = FirebaseAuth.instance;

  String? get _uid => firebaseAuth.currentUser?.uid;

  static String contentTypeFor(String path, {required String fallback}) {
    final String lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.m4a') || lower.endsWith('.mp4a')) return 'audio/mp4';
    if (lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return fallback;
  }

  Future<String?> uploadToStorage({
    required File? file,
    required String folderName,
    required String pdfId,
  }) async {
    try {
      final Reference ref = firebaseStorage.ref().child(
        'audios/$_uid/${DateTime.now().microsecondsSinceEpoch}',
      );
      UploadTask task = ref.putFile(
        file!,
        SettableMetadata(
          contentType: contentTypeFor(file.path, fallback: 'audio/mpeg'),
        ),
      );
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
      final Reference publicFolderRef = firebaseStorage.ref().child(
        'public/$_uid/${DateTime.now().microsecondsSinceEpoch}.pdf',
      );

      final uploadTask = publicFolderRef.putFile(
        pdfFile,
        SettableMetadata(contentType: 'application/pdf'),
      );

      final snapshot = await uploadTask.whenComplete(() => null);

      final pdfUrl = await snapshot.ref.getDownloadURL();
      debugPrint('File uploaded to: $pdfUrl');

      return pdfUrl;
    } catch (e) {
      debugPrint('Failed to upload file: $e');
      return null;
    }
  }

  Future<String?> uploadCoverImageToStorage({
    required File? file,
    required String folderName,
  }) async {
    try {
      final Reference ref = firebaseStorage.ref().child(
        'profile/$_uid/${DateTime.now().microsecondsSinceEpoch}',
      );
      UploadTask task = ref.putFile(
        file!,
        SettableMetadata(
          contentType: contentTypeFor(file.path, fallback: 'image/jpeg'),
        ),
      );
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
        '$folderName/$_uid/${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      UploadTask task = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      TaskSnapshot snapshot = await task;
      String url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('❌ Storage Error (Bytes): $e');
      return "";
    }
  }
}
