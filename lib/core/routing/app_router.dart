import 'dart:io';

import 'package:flutter/material.dart';

import '../../features/ai_tools/screens/image_to_text_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

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
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
