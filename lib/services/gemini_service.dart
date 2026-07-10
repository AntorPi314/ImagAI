import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../database/models/settings_model.dart';
import 'ai_base_service.dart';

class GeminiService implements AiBaseService {
  @override
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
    required SettingsModel settings,
  }) async {
    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/${settings.selectedModel}:generateContent?key=${settings.apiKey}',
      ),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': settings.systemPrompt},
          ],
        },
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Encode(imageBytes),
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': settings.temperatureMax,
          'maxOutputTokens': settings.maxOutputTokens,
        },
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error']?['message'] ?? 'Gemini request failed.');
    }

    final candidates = data['candidates'] as List<dynamic>?;
    final parts =
        candidates?.firstOrNull?['content']?['parts'] as List<dynamic>?;
    return (parts?.firstOrNull?['text'] as String?) ?? 'No response';
  }
}
