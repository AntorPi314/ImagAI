<<<<<<< HEAD
import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ImagePickerUtil {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage(ImageSource source) async {
=======
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Holds a picked image as raw bytes plus its file name.
/// Using bytes (instead of `dart:io File`) keeps this working on
/// Web, Android, iOS, and Desktop — `File` is not supported on Flutter Web.
class PickedImage {
  const PickedImage({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

class ImagePickerUtil {
  static final ImagePicker _picker = ImagePicker();

  static Future<PickedImage?> pickImage(ImageSource source) async {
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) {
      return null;
    }

<<<<<<< HEAD
    return File(pickedFile.path);
=======
    final bytes = await pickedFile.readAsBytes();
    return PickedImage(bytes: bytes, name: pickedFile.name);
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
  }
}
