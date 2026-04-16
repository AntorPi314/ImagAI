import 'package:flutter/material.dart';

import '../../../database/local_db_service.dart';
import '../../../database/models/history_model.dart';

class FeatureItem {
  final String title;
  final String iconPath;
  final LinearGradient gradient;
  final bool requiresImage;

  const FeatureItem({
    required this.title,
    required this.iconPath,
    required this.gradient,
    this.requiresImage = false,
  });
}

class HomeController {
  const HomeController();

  static final LocalDbService _localDbService = LocalDbService();

  List<FeatureItem> getFeatures() {
    return const [
      FeatureItem(
        title: 'Math Problem Solver',
        iconPath: 'assets/svg/math.svg',
        requiresImage: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6189F3), Color(0xFF5173CC), Color(0xFF39508D)],
          stops: [0.0, 0.3832, 1.0],
        ),
      ),
      FeatureItem(
        title: 'Medical Report Summarize',
        iconPath: 'assets/svg/medical.svg',
        requiresImage: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCA9595), Color(0xFFDC143C), Color(0xFFFF7F7F)],
          stops: [0.0144, 0.6394, 1.0],
        ),
      ),
      FeatureItem(
        title: 'Skin Issue Detection',
        iconPath: 'assets/svg/skin.svg',
        requiresImage: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3AA39), Color(0xFFE56719), Color(0xFFAFEAAB)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      FeatureItem(
        title: 'Image to Text',
        iconPath: 'assets/svg/image_ai.svg',
        requiresImage: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8181DD), Color(0xFF4CE7AF)],
        ),
      ),
      FeatureItem(
        title: 'AI PDF Viewer',
        iconPath: 'assets/svg/pdf.svg',
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF63049),
            Color(0xFFD02752),
            Color(0xFF8A244B),
            Color(0xFF323D47),
          ],
          stops: [0.0048, 0.3798, 0.6298, 1.0],
        ),
      ),
      FeatureItem(
        title: 'Plant & Disease Identifier',
        iconPath: 'assets/svg/plant.svg',
        requiresImage: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E566D), Color(0xFF34E89E)],
        ),
      ),
      FeatureItem(
        title: 'Image Compression',
        iconPath: 'assets/svg/image_compress.svg',
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEDCE64), Color(0xFFFC506E)],
        ),
      ),
      FeatureItem(
        title: 'Video Compression',
        iconPath: 'assets/svg/video_compress.svg',
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF005461),
            Color(0xFF0C7779),
            Color(0xFF249E94),
            Color(0xFF3BC1A8),
          ],
          stops: [0.0, 0.3894, 0.6683, 1.0],
        ),
      ),
    ];
  }

  Future<List<HistoryModel>> getHistory() {
    return _localDbService.loadHistory();
  }

  String promptForTitle(String title) {
    switch (title) {
      case 'Math Problem Solver':
        return 'Solve this math problem step by step.';
      case 'Medical Report Summarize':
        return 'Summarize this medical report simply.';
      case 'Skin Issue Detection':
        return 'Analyze the visible skin condition.';
      case 'Image to Text':
        return 'Extract all visible text from the image.';
      case 'Plant & Disease Identifier':
        return 'Identify the plant and detect any visible disease.';
      default:
        return 'Analyze this image.';
    }
  }
}
