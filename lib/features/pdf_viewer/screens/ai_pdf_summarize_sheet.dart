import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../database/models/settings_model.dart';

class AiPdfSummarizeSheet extends StatefulWidget {
  const AiPdfSummarizeSheet({
    super.key,
    required this.pageImages,
    required this.pageRange,
    required this.settings,
  });

  final List<Uint8List> pageImages;
  final String pageRange;
  final SettingsModel settings;

  @override
  State<AiPdfSummarizeSheet> createState() => _AiPdfSummarizeSheetState();
}

class _AiPdfSummarizeSheetState extends State<AiPdfSummarizeSheet> {
  bool _isLoading = true;
  String _summary = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _summarize();
  }

  Future<void> _summarize() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _summary = '';
    });

    try {
      final result = await _callGemini();
      setState(() {
        _summary = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Always use Gemini for image-based PDF summarization (vision model)
  Future<String> _callGemini() async {
    final apiKey = widget.settings.apiKey.trim();
    final model = widget.settings.selectedProvider == AIProvider.gemini
        ? widget.settings.selectedModel
        : 'gemini-2.5-flash'; // fallback to Gemini for vision

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    // Build parts: text prompt + images
    final List<Map<String, dynamic>> parts = [
      {
        'text':
<<<<<<< HEAD
            'এই PDF এর page গুলো দেখো এবং বাংলায় একটি সুন্দর summary দাও। '
                'মূল বিষয়গুলো, গুরুত্বপূর্ণ তথ্য, এবং key points উল্লেখ করো। '
                'Markdown formatting ব্যবহার করো।',
=======
            'Look at the pages of this PDF and provide a clear summary. '
                'Mention the main topics, important information, and key points. '
                'Use Markdown formatting.',
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
      },
    ];

    for (final imageBytes in widget.pageImages) {
      final base64Image = base64Encode(imageBytes);
      parts.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': base64Image,
        },
      });
    }

    final body = jsonEncode({
      'contents': [
        {
          'parts': parts,
        }
      ],
      'generationConfig': {
        'temperature': (widget.settings.temperatureMin +
                widget.settings.temperatureMax) /
            2,
        'maxOutputTokens': widget.settings.maxOutputTokens,
      },
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      final decoded = jsonDecode(response.body);
      final message = decoded['error']?['message'] ?? 'Unknown error';
      throw Exception('Gemini Error: $message');
    }

    final decoded = jsonDecode(response.body);
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response from Gemini');
    }

    final content = candidates[0]['content'];
    final parts2 = content['parts'] as List<dynamic>;
    final text = parts2
        .where((p) => p['text'] != null)
        .map((p) => p['text'] as String)
        .join('\n');

    return text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1E35),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── Drag handle ───────────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_sharp,
                        color: AppColors.purple,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: const Text(
                        'AI Summarize',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (!_isLoading)
                      GestureDetector(
                        onTap: _summarize,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.purple.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh_rounded,
                                  size: 14, color: AppColors.purple),
                              SizedBox(width: 4),
                              Text(
                                'Retry',
                                style: TextStyle(
                                  color: AppColors.purple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Page label ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Page (${widget.pageRange}):',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Content ───────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  child: _buildContent(),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252A41),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: MarkdownBody(
        data: _summary,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
            fontSize: 13,
            height: 1.7,
            color: Color(0xFFD1D5DB),
          ),
          h1: const TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          h2: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
          h3: const TextStyle(
              color: Color(0xFFE5E7EB),
              fontSize: 13,
              fontWeight: FontWeight.w600),
          strong: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13),
          listBullet:
              const TextStyle(color: AppColors.purple, fontSize: 13),
          listIndent: 16,
          code: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.green,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: const Text(
                'Analyzing by AI...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Shimmer lines
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF252A41),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: List.generate(7, (i) {
              final widths = [0.9, 1.0, 0.75, 1.0, 0.85, 0.6, 0.95];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 11,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.04),
                        Colors.white.withValues(alpha: 0.09),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widths[i],
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF252A41),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _summarize,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.purple, AppColors.blue],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
<<<<<<< HEAD
                'আবার চেষ্টা করো',
=======
                'Try Again',
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
