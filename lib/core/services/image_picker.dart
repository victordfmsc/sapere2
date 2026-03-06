import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  Future<File?> imagePick({required ImageSource source}) async {
    final pick = ImagePicker();
    final pickedFile =
    await pick.pickImage(source: source, maxHeight: 500, maxWidth: 500);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
}
