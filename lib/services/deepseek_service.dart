import 'dart:convert';
<<<<<<< HEAD
import 'dart:io';
=======
import 'dart:typed_data';
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2

import 'package:http/http.dart' as http;

import '../database/models/settings_model.dart';
import 'ai_base_service.dart';

class DeepseekService implements AiBaseService {
  @override
  Future<String> analyzeImage({
<<<<<<< HEAD
    required File imageFile,
    required String prompt,
    required SettingsModel settings,
  }) async {
    final bytes = await imageFile.readAsBytes();
=======
    required Uint8List imageBytes,
    required String prompt,
    required SettingsModel settings,
  }) async {
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
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
<<<<<<< HEAD
                  'url': 'data:image/jpeg;base64,${base64Encode(bytes)}',
=======
                  'url': 'data:image/jpeg;base64,${base64Encode(imageBytes)}',
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
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
