import '../../../core/constants/api_constants.dart';
import '../../../database/local_db_service.dart';
import '../../../database/models/settings_model.dart';
import '../../../services/gemini_service.dart';

class SettingsController {
  SettingsController({LocalDbService? localDbService, GeminiService? geminiService})
    : _localDbService = localDbService ?? LocalDbService(),
      _geminiService = geminiService ?? GeminiService();

  final LocalDbService _localDbService;
  final GeminiService _geminiService;

  Future<SettingsModel> loadSettings() {
    return _localDbService.loadSettings();
  }

  Future<void> saveSettings(SettingsModel settings) {
    return _localDbService.saveSettings(settings);
  }

  SettingsModel onProviderChanged(SettingsModel settings, AIProvider provider) {
    final firstModel = provider == AIProvider.gemini && settings.geminiLoadedModels.isNotEmpty
        ? settings.geminiLoadedModels.first
        : ApiConstants.modelOptions[provider]!.first;
    return settings.copyWith(
      selectedProvider: provider,
      selectedModel: firstModel,
      apiKey: '',
    );
  }

  /// Fetches the list of Gemini models available for [apiKey] and returns
  /// an updated [SettingsModel] with `geminiLoadedModels` populated and
  /// `selectedModel` pointing at the first loaded model.
  ///
  /// Throws an [Exception] (propagated from [GeminiService.listModels]) on
  /// failure, so callers should wrap this in a try/catch.
  Future<SettingsModel> loadModelsFromApi(
    SettingsModel settings, {
    required String apiKey,
  }) async {
    final models = await _geminiService.listModels(apiKey: apiKey);
    return settings.copyWith(
      geminiLoadedModels: models,
      selectedModel: models.first,
    );
  }
}
