import '../../core/constants/api_constants.dart';

class SettingsModel {
  final AIProvider selectedProvider;
  final String apiKey;
  final String selectedModel;
  final double temperatureMin;
  final double temperatureMax;
  final int maxOutputTokens;
  final String systemPrompt;

  /// Models fetched live from the Gemini API via Settings > Load Models.
  /// Empty until the user loads them at least once; falls back to
  /// [ApiConstants.geminiModels] when empty.
  final List<String> geminiLoadedModels;

  const SettingsModel({
    this.selectedProvider = AIProvider.gemini,
    this.apiKey = '',
    this.selectedModel = ApiConstants.defaultGeminiModel,
    this.temperatureMin = 0.0,
    this.temperatureMax = 1.0,
    this.maxOutputTokens = 8192,
    this.systemPrompt = '',
    this.geminiLoadedModels = const [],
  });

  SettingsModel copyWith({
    AIProvider? selectedProvider,
    String? apiKey,
    String? selectedModel,
    double? temperatureMin,
    double? temperatureMax,
    int? maxOutputTokens,
    String? systemPrompt,
    List<String>? geminiLoadedModels,
  }) {
    return SettingsModel(
      selectedProvider: selectedProvider ?? this.selectedProvider,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      temperatureMin: temperatureMin ?? this.temperatureMin,
      temperatureMax: temperatureMax ?? this.temperatureMax,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      geminiLoadedModels: geminiLoadedModels ?? this.geminiLoadedModels,
    );
  }
}
