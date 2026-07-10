import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../features/ai_tools/screens/image_to_text_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/compression/screens/image_compression_screen.dart';
import '../../features/compression/screens/video_compression_screen.dart';
import '../../features/pdf_viewer/screens/pdf_viewer_screen.dart';
import '../../features/global_chat/screens/global_chat_screen.dart';

class AiToolRouteArgs {
  const AiToolRouteArgs({
    required this.title,
    this.prompt,
    required this.imageBytes,
    this.imageName = 'image.jpg',
    this.resultText,
  });

  final String title;
  final String? prompt;

  /// Raw image bytes — works on Web, Android, iOS, and Desktop.
  final Uint8List imageBytes;
  final String imageName;
  final String? resultText;
}

class AppRouter {
  static const String home = '/';
  static const String settings = '/settings';
  static const String aiToolResult = '/ai-tool-result';
  static const String imageCompression = '/image-compression';
  static const String videoCompression = '/video-compression';
  static const String pdfViewer = '/pdf-viewer';
  static const String globalChat = '/global-chat'; //  this was missing

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

      case pdfViewer:
        final pdfFile = settings.arguments as File;
        return MaterialPageRoute(
          builder: (_) => PdfViewerScreen(pdfFile: pdfFile),
        );

      case globalChat:
        return MaterialPageRoute(builder: (_) => const ChatEntry());

      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
