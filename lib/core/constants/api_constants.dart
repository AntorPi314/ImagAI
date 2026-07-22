enum AIProvider { gemini, deepseek }

class ApiConstants {
  static const String defaultGeminiModel = 'gemini-2.5-flash';

  /// Fallback list shown before the user loads live models from the API
  /// (Settings > Load Models). Once loaded, the live list is used instead.
  static const List<String> geminiModels = [defaultGeminiModel];

  static const List<String> deepseekModels = [
    'deepseek-chat',
    'deepseek-reasoner',
  ];

  static const Map<AIProvider, List<String>> modelOptions = {
    AIProvider.gemini: geminiModels,
    AIProvider.deepseek: deepseekModels,
  };
}

extension AIProviderX on AIProvider {
  String get displayName {
    switch (this) {
      case AIProvider.gemini:
        return 'Gemini';
      case AIProvider.deepseek:
        return 'DeepSeek';
    }
  }
}
