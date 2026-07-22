<<<<<<< HEAD
import 'dart:io';
=======
import 'dart:typed_data';
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2

import '../database/models/settings_model.dart';

abstract class AiBaseService {
  Future<String> analyzeImage({
<<<<<<< HEAD
    required File imageFile,
=======
    required Uint8List imageBytes,
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
    required String prompt,
    required SettingsModel settings,
  });
}
