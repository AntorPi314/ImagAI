import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../database/local_db_service.dart';
import '../../../database/models/history_model.dart';
import '../../../database/models/settings_model.dart';
import '../../../services/ai_base_service.dart';
import '../../../services/deepseek_service.dart';
import '../../../services/gemini_service.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../widgets/result_bottom_sheet.dart';

class AiToolResultScreen extends StatefulWidget {
  const AiToolResultScreen({super.key, required this.args});

  final AiToolRouteArgs args;

  @override
  State<AiToolResultScreen> createState() => _AiToolResultScreenState();
}

class _AiToolResultScreenState extends State<AiToolResultScreen> {
  final LocalDbService _localDbService = LocalDbService();

  bool _isLoading = true;
  String _resultText = '';

  @override
  void initState() {
    super.initState();
    if (widget.args.resultText != null) {
      _resultText = widget.args.resultText!;
      _isLoading = false;
    } else {
      _processImage();
    }
  }

  Future<void> _processImage() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _localDbService.loadSettings();
      if (settings.apiKey.trim().isEmpty) {
        setState(() {
          _resultText = '❌ ${AppStrings.missingApiKey}';
          _isLoading = false;
        });
        return;
      }

      final service = _resolveService(settings);
      final result = await service.analyzeImage(
        imageFile: widget.args.imageFile,
        prompt: widget.args.prompt ?? '',
        settings: settings,
      );

      await _localDbService.addHistoryItem(
        HistoryModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: widget.args.title,
          prompt: widget.args.prompt ?? '',
          resultText: result,
          imagePath: widget.args.imageFile.path,
          fileName: _fileNameFromPath(widget.args.imageFile.path),
          sizeLabel: _fileSizeLabel(widget.args.imageFile),
        ),
      );

      setState(() {
        _resultText = result;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _resultText = 'Error: $error';
        _isLoading = false;
      });
    }
  }

  String _fileNameFromPath(String path) {
    if (path.isEmpty) {
      return 'image';
    }
    return path.split(Platform.pathSeparator).last;
  }

  String _fileSizeLabel(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  AiBaseService _resolveService(SettingsModel settings) {
    switch (settings.selectedProvider) {
      case AIProvider.gemini:
        return GeminiService();
      case AIProvider.deepseek:
        return DeepseekService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: widget.args.title,
              trailing: GestureDetector(
                onTap: _isLoading ? null : _processImage,
                child: Container(
                  width: 45,
                  height: 42.75,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.purple),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          widget.args.imageFile,
                          width: 277,
                          height: 254,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Summarize:',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ResultBottomSheet(
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.purple,
                                ),
                              ),
                            )
                          : MarkdownBody(
                              data: _resultText,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                  height: 1.3,
                                  color: Colors.white,
                                ),
                                h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                h2: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                h3: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                listBullet: const TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
