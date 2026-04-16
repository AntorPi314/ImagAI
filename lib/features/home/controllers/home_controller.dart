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
        return 'Solve this math problem step by step in detail. Show every calculation, explain the logic behind each step clearly, and provide the final answer at the end. Use markdown formatting with headings for each step.';
      case 'Medical Report Summarize':
        return 'Summarize this medical report in detail. Break it down into sections: Patient Information, Key Findings, Diagnosis, Medications/Treatments mentioned, and Recommendations. Use bullet points and make it easy to understand for a non-medical person. Provide the full complete summary without cutting short.';
      case 'Skin Issue Detection':
        return 'You are a skin analysis AI assistant. Analyze the visible skin condition in this image thoroughly. You MUST provide your full prediction and analysis first — do NOT refuse or redirect to a doctor without analyzing. Follow this structure:\n\n1. **Identified Condition**: State what skin condition you predict this is.\n2. **Confidence Level**: How confident you are in this prediction.\n3. **Symptoms Observed**: List visible symptoms you can identify from the image.\n4. **Possible Causes**: What commonly causes this condition.\n5. **Severity Assessment**: Mild, Moderate, or Severe based on what you see.\n6. **Home Care Suggestions**: What the person can do at home to help.\n7. **⚕️ Professional Advice**: At the very end, recommend consulting a dermatologist for proper diagnosis and treatment.\n\nProvide all information completely. Do not cut the response short.';
      case 'Image to Text':
        return 'Extract ALL visible text from this image. Maintain the original formatting, line breaks, and structure as closely as possible. If there are multiple text sections, separate them clearly. Include every piece of text you can read, no matter how small.';
      case 'Plant & Disease Identifier':
        return 'Identify the plant in this image and detect any visible diseases or health issues. Provide:\n1. **Plant Name** (common and scientific)\n2. **Plant Family**\n3. **Health Status**: Healthy or Diseased\n4. **Disease Identified** (if any): Name of disease, symptoms visible, possible causes\n5. **Treatment/Care Tips**: How to treat the disease or maintain the plant\n6. Provide complete detailed information.';
      default:
        return 'Analyze this image thoroughly and provide a complete, detailed response. Use markdown formatting with headings and bullet points.';
    }
  }
}
