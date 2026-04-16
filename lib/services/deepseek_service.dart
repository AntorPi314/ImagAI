import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../database/models/settings_model.dart';
import 'ai_base_service.dart';

class DeepseekService implements AiBaseService {
  @override
  Future<String> analyzeImage({
    required File imageFile,
    required String prompt,
    required SettingsModel settings,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final response = await http.post(
      Uri.parse('https://api.deepseek.com/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${settings.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': settings.selectedModel,
        'messages': [
          if (settings.systemPrompt.trim().isNotEmpty)
            {'role': 'system', 'content': settings.systemPrompt},
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,${base64Encode(bytes)}',
                },
              },
            ],
          },
        ],
        'temperature': settings.temperatureMax,
        'max_tokens': settings.maxOutputTokens,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error']?['message'] ?? 'DeepSeek request failed.');
    }

    return data['choices']?[0]?['message']?['content'] as String? ??
        'No response';
  }
}
