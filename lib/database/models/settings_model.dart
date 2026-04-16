import '../../core/constants/api_constants.dart';

class SettingsModel {
  final AIProvider selectedProvider;
  final String apiKey;
  final String selectedModel;
  final double temperatureMin;
  final double temperatureMax;
  final int maxOutputTokens;
  final String systemPrompt;

  const SettingsModel({
    this.selectedProvider = AIProvider.gemini,
    this.apiKey = '',
    this.selectedModel = ApiConstants.defaultGeminiModel,
    this.temperatureMin = 0.0,
    this.temperatureMax = 1.0,
    this.maxOutputTokens = 1000,
    this.systemPrompt = '',
  });

  SettingsModel copyWith({
    AIProvider? selectedProvider,
    String? apiKey,
    String? selectedModel,
    double? temperatureMin,
    double? temperatureMax,
    int? maxOutputTokens,
    String? systemPrompt,
  }) {
    return SettingsModel(
      selectedProvider: selectedProvider ?? this.selectedProvider,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      temperatureMin: temperatureMin ?? this.temperatureMin,
      temperatureMax: temperatureMax ?? this.temperatureMax,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }
}
