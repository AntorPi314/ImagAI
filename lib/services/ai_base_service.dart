import 'dart:io';

import '../database/models/settings_model.dart';

abstract class AiBaseService {
  Future<String> analyzeImage({
    required File imageFile,
    required String prompt,
    required SettingsModel settings,
  });
}
