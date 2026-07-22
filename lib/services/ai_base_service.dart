import 'dart:typed_data';

import '../database/models/settings_model.dart';

abstract class AiBaseService {
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
    required SettingsModel settings,
  });
}
