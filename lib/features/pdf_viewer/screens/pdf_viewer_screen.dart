import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../../core/constants/app_colors.dart';
import '../../../database/local_db_service.dart';
import 'ai_pdf_summarize_sheet.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.pdfFile});

  final File pdfFile;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen>
    with SingleTickerProviderStateMixin {
  late final PdfControllerPinch _pdfController;

  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _isAiLoading = false;

  late final AnimationController _aiSpinController;

@override
  void initState() {
    super.initState();
    _aiSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    try {
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(widget.pdfFile.path),
      );
    } catch (_) {
      // PDF load error handled by errorBuilder in PdfViewPinch
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _aiSpinController.dispose();
    super.dispose();
  }

  String get _fileName {
    return widget.pdfFile.path.split(Platform.pathSeparator).last;
  }

  // ── Capture visible pages as images and send to AI ─────────────────────────
  Future<void> _onAiTap() async {
    if (_isAiLoading) return;

    setState(() => _isAiLoading = true);
    _aiSpinController.repeat();

    try {
      // Load settings first to check API key
      final settings = await LocalDbService().loadSettings();
      if (!mounted) return;

      if (settings.apiKey.trim().isEmpty) {
        _aiSpinController.stop();
        _aiSpinController.reset();
        setState(() => _isAiLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please add your API Key in Settings first.'),
              backgroundColor: AppColors.purple.withValues(alpha: 0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }

      // Render current visible pages (current page and next if available)
      final pageImages = await _renderVisiblePages();

      _aiSpinController.stop();
      _aiSpinController.reset();
      setState(() => _isAiLoading = false);

      if (!mounted) return;

      // Show bottom sheet with images + AI summary
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AiPdfSummarizeSheet(
          pageImages: pageImages,
          pageRange: _getPageRangeLabel(),
          settings: settings,
        ),
      );
    } catch (e) {
      _aiSpinController.stop();
      _aiSpinController.reset();
      setState(() => _isAiLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Render up to 2 pages as Uint8List images
  Future<List<Uint8List>> _renderVisiblePages() async {
    final List<Uint8List> images = [];
    final doc = await PdfDocument.openFile(widget.pdfFile.path);

    final pagesToRender = <int>[_currentPage];
    if (_currentPage < _totalPages) pagesToRender.add(_currentPage + 1);

    for (final pageNum in pagesToRender) {
      final page = await doc.getPage(pageNum);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
        backgroundColor: '#FFFFFF',
      );
      await page.close();

      if (pageImage != null) {
        images.add(pageImage.bytes);
      }
    }

    await doc.close();
    return images;
  }

  String _getPageRangeLabel() {
    if (_currentPage < _totalPages) {
      return '${_currentPage}-${_currentPage + 1}';
    }
    return '$_currentPage';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Stack(
                children: [
                  // ── PDF View ──────────────────────────────────────────────
                  PdfViewPinch(
                    controller: _pdfController,
                    onDocumentLoaded: (doc) {
                      setState(() {
                        _totalPages = doc.pagesCount;
                        _isLoading = false;
                      });
                    },
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                    },
                    builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                      options: const DefaultBuilderOptions(),
                      documentLoaderBuilder: (_) => Center(
                        child: CircularProgressIndicator(
                          color: AppColors.purple,
                          strokeWidth: 2.5,
                        ),
                      ),
                      pageLoaderBuilder: (_) => Center(
                        child: CircularProgressIndicator(
                          color: AppColors.purple.withValues(alpha: 0.6),
                          strokeWidth: 2,
                        ),
                      ),
                      errorBuilder: (_, error) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: Colors.redAccent, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load PDF.\n$error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Page indicator ────────────────────────────────────────
                  if (!_isLoading && _totalPages > 0)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_currentPage / $_totalPages',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'AI PDF Viewer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_fileName.isNotEmpty)
                  Text(
                    _fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // AI Summarize Button
          GestureDetector(
            onTap: _isAiLoading ? null : _onAiTap,
            child: RotationTransition(
              turns: _aiSpinController,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.purple, AppColors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
