import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import 'models/history_model.dart';
import 'models/settings_model.dart';

class LocalDbService {
  static const String _historyKey = 'history_items';
  static const String _geminiModelsKey = 'geminiLoadedModels';

  Future<SettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final providerName = prefs.getString('provider') ?? AIProvider.gemini.name;
    final provider = AIProvider.values.firstWhere(
      (item) => item.name == providerName,
      orElse: () => AIProvider.gemini,
    );

    final geminiLoadedModels =
        prefs.getStringList(_geminiModelsKey) ?? const <String>[];

    // Models actually available right now for the selected provider:
    // dynamically loaded Gemini models (if any) take priority over the
    // static fallback list so a previously loaded/selected model persists.
    final availableModels = provider == AIProvider.gemini
        ? (geminiLoadedModels.isNotEmpty
              ? geminiLoadedModels
              : ApiConstants.modelOptions[provider]!)
        : ApiConstants.modelOptions[provider]!;

    final storedModel = prefs.getString('model');

    return SettingsModel(
      selectedProvider: provider,
      apiKey: prefs.getString('apiKey') ?? '',
      selectedModel: availableModels.contains(storedModel)
          ? storedModel!
          : availableModels.first,
      temperatureMin: prefs.getDouble('temperatureMin') ?? 0.0,
      temperatureMax: prefs.getDouble('temperatureMax') ?? 1.0,
      maxOutputTokens: prefs.getInt('maxTokens') ?? 8192,
      systemPrompt: prefs.getString('systemPrompt') ?? '',
      geminiLoadedModels: geminiLoadedModels,
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
    await prefs.setStringList(_geminiModelsKey, settings.geminiLoadedModels);
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

  /// Saves [imageBytes] permanently under the app's documents directory
  /// (NOT the cache/temp dir, so it survives app restarts and Android's
  /// cache-clearing) and returns the saved file's path.
  ///
  /// Returns an empty string if saving fails for any reason — callers
  /// should treat that as "no image available" rather than crash.
  Future<String> saveHistoryImage(Uint8List imageBytes, String id) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final historyImagesDir = Directory('${docsDir.path}/history_images');
      if (!await historyImagesDir.exists()) {
        await historyImagesDir.create(recursive: true);
      }

      final file = File('${historyImagesDir.path}/$id.jpg');
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (_) {
      return '';
    }
  }

  Future<void> addHistoryItem(HistoryModel historyModel) async {
    final current = await loadHistory();
    current.insert(0, historyModel);

    // Anything pushed past the 10-item cap is being dropped — delete its
    // saved image file too, so we don't leak files on disk forever.
    if (current.length > 10) {
      final removed = current.sublist(10);
      current.removeRange(10, current.length);
      for (final item in removed) {
        await _deleteImageFile(item.imagePath);
      }
    }
    await _saveHistory(current);
  }

  Future<void> deleteHistoryItem(String id) async {
    final current = await loadHistory();
    final index = current.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final removed = current.removeAt(index);
    await _deleteImageFile(removed.imagePath);
    await _saveHistory(current);
  }

  Future<void> _deleteImageFile(String imagePath) async {
    if (imagePath.trim().isEmpty) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore — nothing useful to do if deletion fails.
    }
  }

  Future<void> _saveHistory(List<HistoryModel> history) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(history.map((item) => item.toJson()).toList());
    await prefs.setString(_historyKey, encoded);
  }
}
