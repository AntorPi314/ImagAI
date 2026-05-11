import 'dart:io';

import 'package:flutter/material.dart';

import '../../features/ai_tools/screens/image_to_text_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/compression/screens/image_compression_screen.dart';
import '../../features/compression/screens/video_compression_screen.dart';
import '../../features/pdf_viewer/screens/pdf_viewer_screen.dart';

class AiToolRouteArgs {
  const AiToolRouteArgs({
    required this.title,
    this.prompt,
    required this.imageFile,
    this.resultText,
  });

  final String title;
  final String? prompt;
  final File imageFile;
  final String? resultText;
}

class AppRouter {
  static const String home = '/';
  static const String settings = '/settings';
  static const String aiToolResult = '/ai-tool-result';
  static const String imageCompression = '/image-compression';
  static const String videoCompression = '/video-compression';
  static const String pdfViewer = '/pdf-viewer'; // ← NEW

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRouter.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case aiToolResult:
        final args = settings.arguments as AiToolRouteArgs;
        return MaterialPageRoute(
          builder: (_) => AiToolResultScreen(args: args),
        );

      case imageCompression:
        final args = settings.arguments as ImageCompressionArgs;
        return MaterialPageRoute(
          builder: (_) => ImageCompressionScreen(args: args),
        );

      case videoCompression:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const VideoCompressionScreen(),
        );

      // ── PDF Viewer route ──────────────────────────────────────────────────
      case pdfViewer:
        final pdfFile = settings.arguments as File;
        return MaterialPageRoute(
          builder: (_) => PdfViewerScreen(pdfFile: pdfFile),
        );

      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}