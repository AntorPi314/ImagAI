import 'dart:convert';
<<<<<<< HEAD
import 'dart:io';
=======
import 'dart:typed_data';
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2

import 'package:http/http.dart' as http;

import '../database/models/settings_model.dart';
import 'ai_base_service.dart';

class GeminiService implements AiBaseService {
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
<<<<<<< HEAD
                  'data': base64Encode(bytes),
=======
                  'data': base64Encode(imageBytes),
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
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
