<<<<<<< HEAD
import 'dart:io';

=======
import 'package:flutter/foundation.dart' show kIsWeb;
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class AiToolResultScreen extends StatefulWidget {
  const AiToolResultScreen({super.key, required this.args});

  final AiToolRouteArgs args;

  @override
  State<AiToolResultScreen> createState() => _AiToolResultScreenState();
}

class _AiToolResultScreenState extends State<AiToolResultScreen>
    with SingleTickerProviderStateMixin {
  final LocalDbService _localDbService = LocalDbService();

  bool _isLoading = true;
  String _resultText = '';

  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (widget.args.resultText != null) {
      _resultText = widget.args.resultText!;
      _isLoading = false;
    } else {
      _processImage();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _processImage() async {
    setState(() => _isLoading = true);
    _spinController.repeat();

    try {
      final settings = await _localDbService.loadSettings();
      if (settings.apiKey.trim().isEmpty) {
        setState(() {
<<<<<<< HEAD
          _resultText = '❌ ${AppStrings.missingApiKey}';
=======
          _resultText = ' ${AppStrings.missingApiKey}';
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
          _isLoading = false;
        });
        _spinController.stop();
        return;
      }

      final service = _resolveService(settings);
      final result = await service.analyzeImage(
<<<<<<< HEAD
        imageFile: widget.args.imageFile,
=======
        imageBytes: widget.args.imageBytes,
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
        prompt: widget.args.prompt ?? '',
        settings: settings,
      );

<<<<<<< HEAD
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
=======
      // History is only kept on native platforms (Android/iOS/Desktop).
      // On Web there is no local file path to persist, and history
      // support isn't needed there.
      if (!kIsWeb) {
        await _localDbService.addHistoryItem(
          HistoryModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: widget.args.title,
            prompt: widget.args.prompt ?? '',
            resultText: result,
            imagePath: '',
            fileName: widget.args.imageName,
            sizeLabel: _fileSizeLabel(widget.args.imageBytes.length),
          ),
        );
      }
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2

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
    _spinController.stop();
    _spinController.reset();
  }

<<<<<<< HEAD
  String _fileNameFromPath(String path) {
    if (path.isEmpty) return 'image';
    return path.split(Platform.pathSeparator).last;
  }

  String _fileSizeLabel(File file) {
    final bytes = file.lengthSync();
=======
  String _fileSizeLabel(int bytes) {
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  AiBaseService _resolveService(SettingsModel settings) {
    switch (settings.selectedProvider) {
      case AIProvider.gemini:
        return GeminiService();
      case AIProvider.deepseek:
        return DeepseekService();
    }
  }

  void _copyToClipboard() {
    if (_resultText.isEmpty || _isLoading) return;
    Clipboard.setData(ClipboardData(text: _resultText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        backgroundColor: AppColors.purple.withValues(alpha: 0.9),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            _buildAppBar(),

            // ── Body ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildImageCard(),
                    const SizedBox(height: 20),
                    _buildResultSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: Text(
                widget.args.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Copy button
          GestureDetector(
            onTap: _copyToClipboard,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.copy_rounded,
                color: Colors.white60,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Regenerate button
          GestureDetector(
            onTap: _isLoading ? null : _processImage,
            child: RotationTransition(
              turns: _spinController,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.purple,
                      AppColors.blue,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Image Card ───────────────────────────────────────────────
  Widget _buildImageCard() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
<<<<<<< HEAD
            child: Image.file(
              widget.args.imageFile,
=======
            // Image.memory works on every platform including Web,
            // unlike Image.file which is not supported on Flutter Web.
            child: Image.memory(
              widget.args.imageBytes,
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Result Section ───────────────────────────────────────────
  Widget _buildResultSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2237),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'AI Response',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(
            color: Colors.white.withValues(alpha: 0.06),
            thickness: 1,
          ),
          const SizedBox(height: 8),

          // Content
          _isLoading ? _buildLoadingShimmer() : _buildMarkdownContent(),
        ],
      ),
    );
  }

  // ─── Loading Shimmer ──────────────────────────────────────────
  Widget _buildLoadingShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(6, (i) {
        final widths = [0.9, 1.0, 0.75, 1.0, 0.85, 0.6];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.white.withValues(alpha: 0.06),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widths[i],
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.04),
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── Markdown Content ─────────────────────────────────────────
  Widget _buildMarkdownContent() {
    return MarkdownBody(
      data: _resultText,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        // Paragraph
        p: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: Color(0xFFD1D5DB),
          letterSpacing: 0.1,
        ),
        // Headings
        h1: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        h2: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        h3: const TextStyle(
          color: Color(0xFFE5E7EB),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        // Strong / Em
        strong: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        em: const TextStyle(
          color: Color(0xFFD1D5DB),
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
        // Lists
        listBullet: const TextStyle(
          color: AppColors.purple,
          fontSize: 13,
        ),
        listIndent: 16,
        // Code
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: AppColors.green,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF151929),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        // Blockquote
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppColors.purple.withValues(alpha: 0.6),
              width: 3,
            ),
          ),
        ),
        blockquotePadding:
            const EdgeInsets.only(left: 12, top: 4, bottom: 4),
        blockquote: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
        // Table
        tableHead: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tableBody: const TextStyle(
          color: Color(0xFFD1D5DB),
          fontSize: 12,
        ),
        tableBorder: TableBorder.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
          borderRadius: BorderRadius.circular(6),
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        // Divider
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
