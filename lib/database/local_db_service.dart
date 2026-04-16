import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import 'models/history_model.dart';
import 'models/settings_model.dart';

class LocalDbService {
  static const String _historyKey = 'history_items';

  Future<SettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final providerName = prefs.getString('provider') ?? AIProvider.gemini.name;
    final provider = AIProvider.values.firstWhere(
      (item) => item.name == providerName,
      orElse: () => AIProvider.gemini,
    );
    final availableModels = ApiConstants.modelOptions[provider]!;
    final storedModel = prefs.getString('model');

    return SettingsModel(
      selectedProvider: provider,
      apiKey: prefs.getString('apiKey') ?? '',
      selectedModel: availableModels.contains(storedModel)
          ? storedModel!
          : availableModels.first,
      temperatureMin: prefs.getDouble('temperatureMin') ?? 0.0,
      temperatureMax: prefs.getDouble('temperatureMax') ?? 1.0,
      maxOutputTokens: prefs.getInt('maxTokens') ?? 1000,
      systemPrompt: prefs.getString('systemPrompt') ?? '',
    );
  }

  Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiKey', settings.apiKey);
    await prefs.setString('model', settings.selectedModel);
    await prefs.setString('provider', settings.selectedProvider.name);
    await prefs.setString('systemPrompt', settings.systemPrompt);
    await prefs.setInt('maxTokens', settings.maxOutputTokens);
    await prefs.setDouble('temperatureMin', settings.temperatureMin);
    await prefs.setDouble('temperatureMax', settings.temperatureMax);
  }

  Future<List<HistoryModel>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      return <HistoryModel>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => HistoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addHistoryItem(HistoryModel historyModel) async {
    final current = await loadHistory();
    current.insert(0, historyModel);
    if (current.length > 10) {
      current.removeRange(10, current.length);
    }
    await _saveHistory(current);
  }

  Future<void> _saveHistory(List<HistoryModel> history) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(history.map((item) => item.toJson()).toList());
    await prefs.setString(_historyKey, encoded);
  }
}
