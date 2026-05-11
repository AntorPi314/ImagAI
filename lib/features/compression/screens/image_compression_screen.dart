import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class ImageCompressionArgs {
  final File imageFile;
  const ImageCompressionArgs({required this.imageFile});
}

class ImageCompressionScreen extends StatefulWidget {
  final ImageCompressionArgs args;
  const ImageCompressionScreen({super.key, required this.args});

  @override
  State<ImageCompressionScreen> createState() => _ImageCompressionScreenState();
}

class _ImageCompressionScreenState extends State<ImageCompressionScreen> {
  double _quality = 90;
  String _format = 'jpg';
  bool _isCompressing = false;
  File? _compressedFile;
  String? _errorMessage;

  final List<String> _formats = ['jpg', 'png', 'webp'];

  String get _originalSizeLabel {
    final bytes = widget.args.imageFile.lengthSync();
    return _formatSize(bytes);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get _originalFormat {
    final ext = widget.args.imageFile.path.split('.').last.toLowerCase();
    return ext.toUpperCase();
  }

  Future<void> _compress() async {
    setState(() {
      _isCompressing = true;
      _compressedFile = null;
      _errorMessage = null;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.$_format';

      // ffmpeg quality: jpg uses -q:v (2=best, 31=worst), webp/png uses different
      String ffmpegCommand;
      if (_format == 'jpg') {
        final qValue = (31 - (_quality / 100 * 29)).round().clamp(2, 31);
        ffmpegCommand =
            '-i "${widget.args.imageFile.path}" -q:v $qValue "$outputPath"';
      } else if (_format == 'webp') {
        ffmpegCommand =
            '-i "${widget.args.imageFile.path}" -quality ${_quality.round()} "$outputPath"';
      } else {
        // png - lossless, compression level
        ffmpegCommand =
            '-i "${widget.args.imageFile.path}" -compression_level 9 "$outputPath"';
      }

      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          _compressedFile = File(outputPath);
          _isCompressing = false;
        });
      } else {
        final logs = await session.getLogsAsString();
        setState(() {
          _errorMessage = 'Compression failed. Check format/quality.';
          _isCompressing = false;
        });
        debugPrint('FFmpeg error: $logs');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isCompressing = false;
      });
    }
  }

  Future<void> _saveToGallery() async {
    if (_compressedFile == null) return;

    try {
      final dir = Directory('/storage/emulated/0/Pictures/ImagAI');
      if (!await dir.exists()) await dir.create(recursive: true);

      final fileName =
          'ImagAI_${DateTime.now().millisecondsSinceEpoch}.$_format';
      final savedFile = await _compressedFile!.copy('${dir.path}/$fileName');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: ${savedFile.path.split('/').last}'),
          backgroundColor: AppColors.green.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(title: 'Image Compression'),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 27, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        _compressedFile ?? widget.args.imageFile,
                        width: double.infinity,
                        height: 247,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // File Info Row
                    Row(
                      children: [
                        Expanded(
                          child: _infoBox(
                            'File Size: $_originalSizeLabel\nFormat: $_originalFormat',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _infoBox(
                            _compressedFile != null
                                ? 'Compressed: ${_formatSize(_compressedFile!.lengthSync())}\nSaved: ${_calculateSaving()}%'
                                : 'Compressed: --\nSaved: --',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Options',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Quality Slider
                    _qualityRow(),

                    const SizedBox(height: 12),

                    // Format Selector
                    _formatRow(),

                    const SizedBox(height: 24),

                    // Error message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 13),
                        ),
                      ),

                    // Compress Button
                    _gradientButton(
                      label: _isCompressing ? 'Compressing...' : 'Compress',
                      onTap: _isCompressing ? null : _compress,
                    ),

                    const SizedBox(height: 12),

                    // Save Button (only after compressed)
                    if (_compressedFile != null)
                      _gradientButton(
                        label: 'Save to Gallery',
                        colors: const [
                          Color(0xFF1E566D),
                          Color(0xFF34E89E),
                        ],
                        onTap: _saveToGallery,
                      ),

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

  String _calculateSaving() {
    if (_compressedFile == null) return '0';
    final original = widget.args.imageFile.lengthSync();
    final compressed = _compressedFile!.lengthSync();
    final saving = ((original - compressed) / original * 100);
    return saving.toStringAsFixed(1);
  }

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))
        ],
      ),
      child: Text(
        text,
        style:
            const TextStyle(color: Colors.white, fontSize: 12, height: 1.7),
      ),
    );
  }

  Widget _qualityRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quality:',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_quality.toInt()}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.purple,
              inactiveTrackColor: AppColors.background,
              thumbColor: AppColors.purple,
              overlayColor: AppColors.purple.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _quality,
              min: 10,
              max: 100,
              divisions: 18,
              onChanged: (val) => setState(() => _quality = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Format:',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          Row(
            children: _formats.map((fmt) {
              final isSelected = _format == fmt;
              return GestureDetector(
                onTap: () => setState(() => _format = fmt),
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.purple.withValues(alpha: 0.3)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: AppColors.purple)
                        : null,
                  ),
                  child: Text(
                    fmt.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? AppColors.purple : Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    List<Color>? colors,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 53,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors ??
                const [
                  Color(0xFFA5949F),
                  Color(0xFF6C60CA),
                  Color(0xFF931795),
                ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))
          ],
        ),
        alignment: Alignment.center,
        child: _isCompressing && label.contains('Compress')
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}