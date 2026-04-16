import '../../../core/constants/api_constants.dart';
import '../../../database/local_db_service.dart';
import '../../../database/models/settings_model.dart';

class SettingsController {
  SettingsController({LocalDbService? localDbService})
    : _localDbService = localDbService ?? LocalDbService();

  final LocalDbService _localDbService;

  Future<SettingsModel> loadSettings() {
    return _localDbService.loadSettings();
  }

  Future<void> saveSettings(SettingsModel settings) {
    return _localDbService.saveSettings(settings);
  }

  SettingsModel onProviderChanged(SettingsModel settings, AIProvider provider) {
    final firstModel = ApiConstants.modelOptions[provider]!.first;
    return settings.copyWith(
      selectedProvider: provider,
      selectedModel: firstModel,
      apiKey: '',
    );
  }
}
