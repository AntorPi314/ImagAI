import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_app_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums & Models
// ─────────────────────────────────────────────────────────────────────────────

enum _BitrateMode { targetSize, customBitrate }

class _CompressionPreset {
  final String label;
  final String description;
  final int crf; // Constant Rate Factor (lower = better quality)
  final String icon;

  const _CompressionPreset({
    required this.label,
    required this.description,
    required this.crf,
    required this.icon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class VideoCompressionScreen extends StatefulWidget {
  const VideoCompressionScreen({super.key});

  @override
  State<VideoCompressionScreen> createState() => _VideoCompressionScreenState();
}

class _VideoCompressionScreenState extends State<VideoCompressionScreen>
    with TickerProviderStateMixin {
  // ── Video ──────────────────────────────────────────────────────────────────
  String? _videoPath;
  Uint8List? _thumbnailBytes;

  // ── Metadata ───────────────────────────────────────────────────────────────
  String _fileSize = '--';
  String _duration = '--';
  String _width = '--';
  String _height = '--';
  String _videoBitrate = '--';
  String _audioBitrate = '--';
  String _videoFormat = '--';
  String _audioCodecRaw = '--';

  int _totalSeconds = 0;
  double _originalSizeMB = 0;
  int _originalVideoBitrateKbps = 0; // parsed raw kbps for bitrate slider max

  // ── Settings ───────────────────────────────────────────────────────────────
  _BitrateMode _bitrateMode = _BitrateMode.targetSize;

  // Target-size mode
  double _desiredSizeMB = 20;

  // Custom bitrate mode
  double _customVideoBitrateKbps = 2000;
  static const double _minBitrateKbps = 200;
  static const double _maxBitrateKbps = 50000;

  int _audioQuality = 128;
  String _outputFormat = 'mp4';

  int _selectedPresetIndex = 1; // Medium by default

  final List<_CompressionPreset> _presets = const [
    _CompressionPreset(
      label: 'Low',
      description: 'Smallest file\nLower quality',
      crf: 35,
      icon: '🗜️',
    ),
    _CompressionPreset(
      label: 'Medium',
      description: 'Balanced\nRecommended',
      crf: 28,
      icon: '⚖️',
    ),
    _CompressionPreset(
      label: 'High',
      description: 'Best quality\nLarger file',
      crf: 20,
      icon: '💎',
    ),
  ];

  final List<String> _formats = ['mp4', 'mkv', 'webm'];
  final List<int> _audioQualities = [64, 96, 128, 192, 256, 320];

  final TextEditingController _cutFromController = TextEditingController(
    text: '00:00',
  );
  final TextEditingController _cutToController = TextEditingController(
    text: '00:00',
  );

  // ── Live Estimation ────────────────────────────────────────────────────────
  double _estimatedOutputMB = 0;
  double _estimatedSaving = 0;
  double _estimatedVideoBitrateDisplay = 0;

  // ── States ─────────────────────────────────────────────────────────────────
  bool _isCompressing = false;
  bool _isLoadingMetadata = false;
  bool _metadataError = false;
  bool _isThumbnailLoading = false;
  bool _thumbnailError = false;

  double _progress = 0;
  File? _compressedFile;
  String? _errorMessage;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _cutFromController.addListener(_updateEstimation);
    _cutToController.addListener(_updateEstimation);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_videoPath == null) {
      final path = ModalRoute.of(context)?.settings.arguments as String?;
      if (path != null && path.isNotEmpty) {
        _videoPath = path;
        _loadMetadata(path);
        _generateThumbnail(path);
      }
    }
  }

  @override
  void dispose() {
    _cutFromController.dispose();
    _cutToController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Thumbnail Generation ───────────────────────────────────────────────────
  Future<void> _generateThumbnail(String videoPath) async {
    if (!mounted) return;
    setState(() {
      _isThumbnailLoading = true;
      _thumbnailError = false;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath =
          '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Extract frame at 1 second (or 0.5s for very short videos)
      final seekTime = _totalSeconds > 2 ? '00:00:01' : '00:00:00';
      final command =
          '-ss $seekTime -i "$videoPath" -frames:v 1 -q:v 2 -vf "scale=640:-1" "$thumbPath" -y';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (!mounted) return;

      if (ReturnCode.isSuccess(returnCode)) {
        final thumbFile = File(thumbPath);
        if (await thumbFile.exists()) {
          final bytes = await thumbFile.readAsBytes();
          setState(() {
            _thumbnailBytes = bytes;
            _isThumbnailLoading = false;
          });
          return;
        }
      }

      setState(() {
        _thumbnailError = true;
        _isThumbnailLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _thumbnailError = true;
        _isThumbnailLoading = false;
      });
    }
  }

  // ── Metadata Loading ───────────────────────────────────────────────────────
  Future<void> _loadMetadata(String path) async {
    if (!mounted) return;
    setState(() {
      _isLoadingMetadata = true;
      _metadataError = false;
    });

    try {
      final file = File(path);
      if (!file.existsSync()) {
        setState(() {
          _metadataError = true;
          _isLoadingMetadata = false;
        });
        return;
      }

      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();

      if (info == null) {
        await _loadBasicInfo(file);
        return;
      }

      final streams = info.getStreams() ?? [];
      String vBitrate = '--';
      String aBitrate = '--';
      String vCodec = '--';
      String aCodec = '--';
      String width = '--';
      String height = '--';
      int rawVideoBitrateKbps = 0;

      for (final stream in streams) {
        final type = stream.getType()?.toLowerCase();
        if (type == 'video') {
          final rawBr = stream.getBitrate();
          vBitrate = _formatBitrate(rawBr);
          rawVideoBitrateKbps = _parseBitrateToKbps(rawBr);
          vCodec = stream.getCodec()?.toUpperCase() ?? '--';
          width = stream.getWidth()?.toString() ?? '--';
          height = stream.getHeight()?.toString() ?? '--';
        } else if (type == 'audio') {
          aBitrate = _formatBitrate(stream.getBitrate());
          aCodec = stream.getCodec()?.toUpperCase() ?? '--';
        }
      }

      final durationSec =
          double.tryParse(info.getDuration() ?? '0') ?? 0;
      _totalSeconds = durationSec.toInt();
      final dur = Duration(seconds: _totalSeconds);
      final formattedDuration =
          '${dur.inMinutes.toString().padLeft(2, '0')}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}';

      final bytes = await file.length();
      final sizeMB = bytes / (1024 * 1024);
      _originalSizeMB = sizeMB;

      final ext = path.split('.').last.toLowerCase();

      if (!mounted) return;
      setState(() {
        _fileSize = '${sizeMB.toStringAsFixed(1)} MB';
        _duration = formattedDuration;
        _width = width;
        _height = height;
        _videoBitrate = vBitrate;
        _audioBitrate = aBitrate;
        _videoFormat = ext.toUpperCase();
        _audioCodecRaw = aCodec;
        _originalVideoBitrateKbps = rawVideoBitrateKbps;
        _desiredSizeMB = double.parse((sizeMB * 0.6).toStringAsFixed(1));
        _customVideoBitrateKbps = rawVideoBitrateKbps > 0
            ? (rawVideoBitrateKbps * 0.7).clamp(_minBitrateKbps, _maxBitrateKbps)
            : 2000;
        _cutToController.text = formattedDuration;
        _isLoadingMetadata = false;
      });

      _updateEstimation();

      // Re-generate thumbnail now that we know duration
      if (_thumbnailBytes == null && !_isThumbnailLoading) {
        _generateThumbnail(path);
      }
    } catch (e) {
      debugPrint('Metadata error: $e');
      if (!mounted) return;
      setState(() {
        _metadataError = true;
        _isLoadingMetadata = false;
      });
    }
  }

  Future<void> _loadBasicInfo(File file) async {
    final bytes = await file.length();
    final sizeMB = bytes / (1024 * 1024);
    _originalSizeMB = sizeMB;
    if (!mounted) return;
    setState(() {
      _fileSize = '${sizeMB.toStringAsFixed(1)} MB';
      _desiredSizeMB = double.parse((sizeMB * 0.6).toStringAsFixed(1));
      _isLoadingMetadata = false;
    });
    _updateEstimation();
  }

  // ── Estimation ─────────────────────────────────────────────────────────────
  void _updateEstimation() {
    if (_totalSeconds <= 0) return;

    final fromSec = _parseTimeToSeconds(_cutFromController.text.trim());
    final toSec = _parseTimeToSeconds(_cutToController.text.trim());
    final effectiveDuration =
        (toSec > fromSec ? toSec - fromSec : _totalSeconds).clamp(1, 999999);

    double videoBitrateKbps;

    if (_bitrateMode == _BitrateMode.targetSize) {
      final totalBitrate = (_desiredSizeMB * 8 * 1024) / effectiveDuration;
      videoBitrateKbps = (totalBitrate - _audioQuality).clamp(100.0, 50000.0);
    } else {
      videoBitrateKbps = _customVideoBitrateKbps;
    }

    final estimatedSize =
        ((videoBitrateKbps + _audioQuality) * effectiveDuration) / (8 * 1024);

    final saved = _originalSizeMB > 0
        ? ((_originalSizeMB - estimatedSize) / _originalSizeMB * 100)
            .clamp(0.0, 100.0)
        : 0.0;

    setState(() {
      _estimatedOutputMB = estimatedSize;
      _estimatedSaving = saved;
      _estimatedVideoBitrateDisplay = videoBitrateKbps;
    });
  }

  // ── Compression ────────────────────────────────────────────────────────────
  Future<void> _compress() async {
    if (_videoPath == null) return;

    setState(() {
      _isCompressing = true;
      _compressedFile = null;
      _errorMessage = null;
      _progress = 0;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.$_outputFormat';

      final fromSec = _parseTimeToSeconds(_cutFromController.text.trim());
      final toSec = _parseTimeToSeconds(_cutToController.text.trim());
      final hasCut = toSec > fromSec;
      final effectiveDuration =
          (hasCut ? toSec - fromSec : _totalSeconds).clamp(1, 999999);

      double videoBitrateKbps;
      if (_bitrateMode == _BitrateMode.targetSize) {
        final totalBitrateKbps =
            (_desiredSizeMB * 8 * 1024) / effectiveDuration;
        videoBitrateKbps =
            (totalBitrateKbps - _audioQuality).clamp(100.0, 50000.0);
      } else {
        videoBitrateKbps = _customVideoBitrateKbps;
      }

      final isWebm = _outputFormat == 'webm';
      final videoCodec = isWebm ? 'libvpx-vp9' : 'libx264';
      final audioCodec = isWebm ? 'libvorbis' : 'aac';

      // Build ffmpeg arguments
      final args = <String>['-y'];

      if (hasCut) {
        args.addAll([
          '-ss', _cutFromController.text.trim(),
          '-to', _cutToController.text.trim(),
        ]);
      }

      args.addAll([
        '-i', _videoPath!,
        '-c:v', videoCodec,
        '-b:v', '${videoBitrateKbps.toInt()}k',
      ]);

      // Add CRF for quality control when using libx264
      if (!isWebm) {
        args.addAll(['-crf', _presets[_selectedPresetIndex].crf.toString()]);
        args.addAll(['-preset', 'medium']);
      }

      args.addAll([
        '-c:a', audioCodec,
        '-b:a', '${_audioQuality}k',
        '-movflags', '+faststart', // For mp4 web streaming
        outputPath,
      ]);

      final command = args.join(' ');
      debugPrint('FFmpeg command: $command');

      await FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();
          if (!mounted) return;
          if (ReturnCode.isSuccess(returnCode)) {
            setState(() {
              _compressedFile = File(outputPath);
              _isCompressing = false;
              _progress = 1.0;
            });
          } else {
            final logs = await session.getAllLogs();
            final errorLog = logs.map((l) => l.getMessage()).join('\n');
            debugPrint('FFmpeg error logs:\n$errorLog');
            setState(() {
              _errorMessage = 'Compression failed. Try adjusting the settings.';
              _isCompressing = false;
            });
          }
        },
        null,
        (statistics) {
          final processed = statistics.getTime() / 1000.0;
          if (effectiveDuration > 0 && mounted) {
            setState(() {
              _progress = (processed / effectiveDuration).clamp(0.0, 0.99);
            });
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isCompressing = false;
      });
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _saveToStorage() async {
    if (_compressedFile == null) return;

    try {
      final dir = Directory('/storage/emulated/0/Movies/ImagAI');
      if (!await dir.exists()) await dir.create(recursive: true);

      final fileName =
          'ImagAI_video_${DateTime.now().millisecondsSinceEpoch}.$_outputFormat';
      final savedFile = await _compressedFile!.copy('${dir.path}/$fileName');

      if (!mounted) return;
      _showSnack(
        'Saved: ${savedFile.path.split('/').last}',
        color: AppColors.green,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Save failed: $e', color: Colors.redAccent);
    }
  }

  void _showSnack(
    String msg, {
    Color color = Colors.white,
    IconData icon = Icons.info_rounded,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: TextStyle(color: color))),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  int _parseTimeToSeconds(String time) {
    final parts = time.split(':');
    if (parts.length == 3) {
      return (int.tryParse(parts[0]) ?? 0) * 3600 +
          (int.tryParse(parts[1]) ?? 0) * 60 +
          (int.tryParse(parts[2]) ?? 0);
    }
    if (parts.length == 2) {
      return (int.tryParse(parts[0]) ?? 0) * 60 +
          (int.tryParse(parts[1]) ?? 0);
    }
    return 0;
  }

  String _formatBitrate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '--';
    final val = double.tryParse(raw.trim()) ?? 0;
    if (val == 0) return '--';
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)} Mbps';
    return '${(val / 1000).toStringAsFixed(0)} kbps';
  }

  int _parseBitrateToKbps(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 0;
    final val = double.tryParse(raw.trim()) ?? 0;
    return (val / 1000).toInt();
  }

  String _compressedSizeLabel() {
    if (_compressedFile == null) return '--';
    final bytes = _compressedFile!.lengthSync();
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _savedPercent() {
    if (_compressedFile == null || _videoPath == null) return '0';
    final original = File(_videoPath!).lengthSync();
    final compressed = _compressedFile!.lengthSync();
    if (original == 0) return '0';
    return ((original - compressed) / original * 100).toStringAsFixed(1);
  }

  String _formatBitrateKbps(double kbps) {
    if (kbps >= 1000) return '${(kbps / 1000).toStringAsFixed(1)} Mbps';
    return '${kbps.toInt()} kbps';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(title: 'Video Compression'),
            Expanded(
              child: _videoPath == null
                  ? _emptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Thumbnail / Preview ──────────────────────────
                          _thumbnailCard(),
                          const SizedBox(height: 16),

                          // ── Metadata Grid ────────────────────────────────
                          _metadataGrid(),
                          const SizedBox(height: 24),

                          // ── Section: Compression Settings ────────────────
                          _sectionTitle('Compression Settings'),
                          const SizedBox(height: 14),

                          // ── Estimate Card ────────────────────────────────
                          _estimateCard(),
                          const SizedBox(height: 14),

                          // ── Quality Preset ───────────────────────────────
                          _presetSection(),
                          const SizedBox(height: 14),

                          // ── Bitrate Mode Toggle ──────────────────────────
                          _bitrateToggle(),
                          const SizedBox(height: 14),

                          // ── Size or Bitrate Slider ───────────────────────
                          if (_bitrateMode == _BitrateMode.targetSize)
                            _sizeSection()
                          else
                            _videoBitrateSection(),
                          const SizedBox(height: 14),

                          // ── Audio Quality ────────────────────────────────
                          _audioQualitySection(),
                          const SizedBox(height: 14),

                          // ── Cut Range ────────────────────────────────────
                          _cutSection(),
                          const SizedBox(height: 14),

                          // ── Output Format ────────────────────────────────
                          _formatSection(),
                          const SizedBox(height: 24),

                          // ── Progress ─────────────────────────────────────
                          if (_isCompressing) ...[
                            _progressBar(),
                            const SizedBox(height: 20),
                          ],

                          // ── Error ─────────────────────────────────────────
                          if (_errorMessage != null) ...[
                            _errorCard(),
                            const SizedBox(height: 14),
                          ],

                          // ── Compress Button ───────────────────────────────
                          _gradientButton(
                            label: _isCompressing
                                ? 'Compressing...'
                                : 'Compress Video',
                            icon: Icons.compress_rounded,
                            onTap: _isCompressing ? null : _compress,
                          ),

                          // ── Result ────────────────────────────────────────
                          if (_compressedFile != null) ...[
                            const SizedBox(height: 16),
                            _compressedResult(),
                            const SizedBox(height: 14),
                            _gradientButton(
                              label: 'Save To Storage',
                              icon: Icons.save_alt_rounded,
                              colors: const [
                                Color(0xFF1D976C),
                                Color(0xFF93F9B9),
                              ],
                              onTap: _saveToStorage,
                            ),
                          ],

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Widgets
  // ─────────────────────────────────────────────────────────────────────────

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.video_library_rounded, color: Colors.white24, size: 64),
          SizedBox(height: 16),
          Text(
            'No video selected.',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ── Thumbnail Card ─────────────────────────────────────────────────────────
  Widget _thumbnailCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 220,
        width: double.infinity,
        color: const Color(0xFF1E1E38),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: Thumbnail or placeholder
            if (_thumbnailBytes != null)
              Image.memory(
                _thumbnailBytes!,
                fit: BoxFit.cover,
              )
            else if (_isThumbnailLoading)
              _thumbnailShimmer()
            else
              _thumbnailFallback(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),

            // Play icon (shown when thumbnail exists)
            if (_thumbnailBytes != null)
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.45),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7), width: 2),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),

            // File name & info
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _videoPath!.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _chipLabel(_duration),
                      const SizedBox(width: 8),
                      if (_width != '--') _chipLabel('$_width×$_height'),
                      const SizedBox(width: 8),
                      _chipLabel(_videoFormat),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailShimmer() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) => Container(
        color: Color.lerp(
          const Color(0xFF1E1E38),
          const Color(0xFF2E2E4E),
          _pulseAnimation.value,
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_search_rounded, color: Colors.white24, size: 40),
              SizedBox(height: 10),
              Text(
                'Generating thumbnail…',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnailFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1E38), Color(0xFF29294F)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.video_file_rounded,
          color: Colors.white24,
          size: 56,
        ),
      ),
    );
  }

  Widget _chipLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
    );
  }

  // ── Metadata Grid ──────────────────────────────────────────────────────────
  Widget _metadataGrid() {
    if (_isLoadingMetadata) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            color: AppColors.purple,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _infoCard('File Size', _fileSize, Icons.folder_outlined)),
            const SizedBox(width: 10),
            Expanded(child: _infoCard('Duration', _duration, Icons.timer_outlined)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _infoCard('Resolution', '$_width×$_height',
                    Icons.aspect_ratio_rounded)),
            const SizedBox(width: 10),
            Expanded(
                child: _infoCard('Video Bitrate', _videoBitrate,
                    Icons.speed_rounded)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _infoCard('Audio Bitrate', _audioBitrate,
                    Icons.volume_up_rounded)),
            const SizedBox(width: 10),
            Expanded(
                child: _infoCard('Audio Codec', _audioCodecRaw,
                    Icons.music_note_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.purple, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Estimate Card ──────────────────────────────────────────────────────────
  Widget _estimateCard() {
    final isPositive = _estimatedSaving > 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded,
                  color: AppColors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Estimated Output',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _estimateItem(
                  'Output Size',
                  '${_estimatedOutputMB.toStringAsFixed(1)} MB',
                  AppColors.blue,
                ),
              ),
              Expanded(
                child: _estimateItem(
                  'Space Saved',
                  '${_estimatedSaving.toStringAsFixed(1)}%',
                  isPositive ? AppColors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _estimateItem(
                  'Video Bitrate',
                  _formatBitrateKbps(_estimatedVideoBitrateDisplay),
                  Colors.white70,
                ),
              ),
              Expanded(
                child: _estimateItem(
                  'Audio Bitrate',
                  '$_audioQuality kbps',
                  Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _estimateItem(String title, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 5),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  // ── Quality Preset ─────────────────────────────────────────────────────────
  Widget _presetSection() {
    return _settingsCard(
      title: 'Quality Preset',
      icon: Icons.tune_rounded,
      child: Row(
        children: List.generate(_presets.length, (i) {
          final preset = _presets[i];
          final isSelected = _selectedPresetIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPresetIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: EdgeInsets.only(
                  left: i == 0 ? 0 : 6,
                  right: i == _presets.length - 1 ? 0 : 6,
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.purple.withValues(alpha: 0.2)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? AppColors.purple : Colors.white10,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(preset.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 6),
                    Text(
                      preset.label,
                      style: TextStyle(
                        color: isSelected ? AppColors.purple : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preset.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Bitrate Mode Toggle ────────────────────────────────────────────────────
  Widget _bitrateToggle() {
    return _settingsCard(
      title: 'Bitrate Control',
      icon: Icons.swap_horiz_rounded,
      child: Row(
        children: [
          Expanded(
            child: _toggleChip(
              label: 'Target Size',
              icon: Icons.data_usage_rounded,
              selected: _bitrateMode == _BitrateMode.targetSize,
              onTap: () {
                setState(() => _bitrateMode = _BitrateMode.targetSize);
                _updateEstimation();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _toggleChip(
              label: 'Custom Bitrate',
              icon: Icons.speed_rounded,
              selected: _bitrateMode == _BitrateMode.customBitrate,
              onTap: () {
                setState(() => _bitrateMode = _BitrateMode.customBitrate);
                _updateEstimation();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple.withValues(alpha: 0.2)
              : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.purple : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? AppColors.purple : Colors.white38),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.purple : Colors.white54,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Size Section ───────────────────────────────────────────────────────────
  Widget _sizeSection() {
    return _settingsCard(
      title: 'Desired File Size',
      icon: Icons.folder_outlined,
      badge: '${_desiredSizeMB.toStringAsFixed(1)} MB',
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: AppColors.purple,
          thumbColor: AppColors.purple,
          inactiveTrackColor: AppColors.background,
          overlayColor: AppColors.purple.withValues(alpha: 0.2),
        ),
        child: Slider(
          value: _desiredSizeMB.clamp(1.0, 500.0),
          min: 1,
          max: 500,
          divisions: 499,
          onChanged: (v) {
            setState(() => _desiredSizeMB = v);
            _updateEstimation();
          },
        ),
      ),
    );
  }

  // ── Custom Video Bitrate ───────────────────────────────────────────────────
  Widget _videoBitrateSection() {
    return _settingsCard(
      title: 'Video Bitrate',
      icon: Icons.speed_rounded,
      badge: _formatBitrateKbps(_customVideoBitrateKbps),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.blue,
              thumbColor: AppColors.blue,
              inactiveTrackColor: AppColors.background,
              overlayColor: AppColors.blue.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _customVideoBitrateKbps.clamp(
                  _minBitrateKbps, _maxBitrateKbps),
              min: _minBitrateKbps,
              max: _maxBitrateKbps,
              divisions: 498,
              onChanged: (v) {
                setState(() => _customVideoBitrateKbps = v);
                _updateEstimation();
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bitratePresetChip('Low', 500),
              _bitratePresetChip('SD', 1500),
              _bitratePresetChip('HD', 4000),
              _bitratePresetChip('FHD', 8000),
              _bitratePresetChip('4K', 20000),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bitratePresetChip(String label, double kbps) {
    final isSelected =
        (_customVideoBitrateKbps - kbps).abs() < 1;
    return GestureDetector(
      onTap: () {
        setState(() => _customVideoBitrateKbps = kbps);
        _updateEstimation();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blue.withValues(alpha: 0.2)
              : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: isSelected ? AppColors.blue : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.blue : Colors.white54,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ── Audio Quality ──────────────────────────────────────────────────────────
  Widget _audioQualitySection() {
    return _settingsCard(
      title: 'Audio Quality',
      icon: Icons.music_note_rounded,
      badge: '$_audioQuality kbps',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _audioQualities.map((q) {
          final isSelected = _audioQuality == q;
          return GestureDetector(
            onTap: () {
              setState(() => _audioQuality = q);
              _updateEstimation();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.purple.withValues(alpha: 0.2)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.purple : Colors.white10,
                ),
              ),
              child: Text(
                '${q}k',
                style: TextStyle(
                  color: isSelected ? AppColors.purple : Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Cut Section ────────────────────────────────────────────────────────────
  Widget _cutSection() {
    return _settingsCard(
      title: 'Trim Video',
      icon: Icons.content_cut_rounded,
      child: Row(
        children: [
          Expanded(
            child: _timeField(title: 'From', controller: _cutFromController),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_rounded,
              color: Colors.white24, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: _timeField(title: 'To', controller: _cutToController),
          ),
        ],
      ),
    );
  }

  Widget _timeField({
    required String title,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
          keyboardType: TextInputType.datetime,
          decoration: InputDecoration(
            hintText: '00:00',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          onChanged: (_) => _updateEstimation(),
        ),
      ],
    );
  }

  // ── Format Section ─────────────────────────────────────────────────────────
  Widget _formatSection() {
    return _settingsCard(
      title: 'Output Format',
      icon: Icons.video_settings_rounded,
      child: Row(
        children: _formats.map((f) {
          final isSelected = _outputFormat == f;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _outputFormat = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.purple
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  f.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Progress Bar ───────────────────────────────────────────────────────────
  Widget _progressBar() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, __) => Icon(
                      Icons.compress_rounded,
                      color: AppColors.purple
                          .withValues(alpha: _pulseAnimation.value),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Compressing…',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor: AppColors.background,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.purple),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error Card ─────────────────────────────────────────────────────────────
  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Compressed Result ──────────────────────────────────────────────────────
  Widget _compressedResult() {
    final savedPct = _savedPercent();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.green, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compression Complete!',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_compressedSizeLabel()} • Saved $savedPct% of original',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Gradient Button ────────────────────────────────────────────────────────
  Widget _gradientButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
    List<Color>? colors,
  }) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors:
                  colors ?? const [Color(0xFF6A5AE0), Color(0xFFB44CFF)],
            ),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: (colors?.first ?? const Color(0xFF6A5AE0))
                          .withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: _isCompressing && label.contains('Compress')
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Compressing…',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Reusable Settings Card ─────────────────────────────────────────────────
  Widget _settingsCard({
    required String title,
    required IconData icon,
    String? badge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.purple, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (badge != null) _badge(badge),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.purple,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}