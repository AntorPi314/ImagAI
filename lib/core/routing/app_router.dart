import 'dart:io';
<<<<<<< HEAD
=======
import 'dart:typed_data';
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2

import 'package:flutter/material.dart';

import '../../features/ai_tools/screens/image_to_text_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/compression/screens/image_compression_screen.dart';
import '../../features/compression/screens/video_compression_screen.dart';
import '../../features/pdf_viewer/screens/pdf_viewer_screen.dart';
<<<<<<< HEAD
=======
import '../../features/global_chat/screens/global_chat_screen.dart';
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2

class AiToolRouteArgs {
  const AiToolRouteArgs({
    required this.title,
    this.prompt,
<<<<<<< HEAD
    required this.imageFile,
=======
    required this.imageBytes,
    this.imageName = 'image.jpg',
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
    this.resultText,
  });

  final String title;
  final String? prompt;
<<<<<<< HEAD
  final File imageFile;
=======

  /// Raw image bytes — works on Web, Android, iOS, and Desktop.
  final Uint8List imageBytes;
  final String imageName;
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
  final String? resultText;
}

class AppRouter {
  static const String home = '/';
  static const String settings = '/settings';
  static const String aiToolResult = '/ai-tool-result';
  static const String imageCompression = '/image-compression';
  static const String videoCompression = '/video-compression';
<<<<<<< HEAD
  static const String pdfViewer = '/pdf-viewer'; // ← NEW
=======
  static const String pdfViewer = '/pdf-viewer';
  static const String globalChat = '/global-chat'; //  this was missing
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2

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

<<<<<<< HEAD
      // ── PDF Viewer route ──────────────────────────────────────────────────
=======
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
      case pdfViewer:
        final pdfFile = settings.arguments as File;
        return MaterialPageRoute(
          builder: (_) => PdfViewerScreen(pdfFile: pdfFile),
        );

<<<<<<< HEAD
=======
      case globalChat:
        return MaterialPageRoute(builder: (_) => const ChatEntry());

>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
