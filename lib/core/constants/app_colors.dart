import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF2E3149);
  static const Color card = Color(0xFF252A41);
  static const Color purple = Color(0xFFA575F2);
  static const Color green = Color(0xFF7CE12B);
  static const Color blue = Color(0xFF68ABE9);
  static const Color historyCard = Color(0xFF1F6F6D);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [green, blue, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Name-based unique avatar colors ──────────────────────────────
  // A curated palette that looks good (saturated but easy on the eyes)
  static const List<Color> _avatarPalette = [
    Color(0xFFE57373), // red
    Color(0xFFF06292), // pink
    Color(0xFFBA68C8), // purple
    Color(0xFF9575CD), // deep purple
    Color(0xFF7986CB), // indigo
    Color(0xFF64B5F6), // blue
    Color(0xFF4FC3F7), // light blue
    Color(0xFF4DD0E1), // cyan
    Color(0xFF4DB6AC), // teal
    Color(0xFF81C784), // green
    Color(0xFFAED581), // light green
    Color(0xFFDCE775), // lime
    Color(0xFFFFD54F), // amber
    Color(0xFFFFB74D), // orange
    Color(0xFFFF8A65), // deep orange
    Color(0xFFA1887F), // brown
    Color(0xFF90A4AE), // blue grey
    Color(0xFF7C4DFF), // vivid purple
    Color(0xFF00BFA5), // vivid teal
    Color(0xFFFF7043), // vivid orange
  ];

  /// Builds a deterministic hash from the name so the same name
  /// always returns the same color (different names get different colors).
  static int _hashName(String name) {
    final normalized = name.trim().toLowerCase();
    int hash = 0;
    for (int i = 0; i < normalized.length; i++) {
      hash = normalized.codeUnitAt(i) + ((hash << 5) - hash);
      hash &= 0x7fffffff; // keep it positive
    }
    return hash;
  }

  /// Unique background color based on the name.
  static Color avatarColorFor(String name) {
    if (name.trim().isEmpty) return purple;
    final hash = _hashName(name);
    return _avatarPalette[hash % _avatarPalette.length];
  }

  /// Checks the background color's luminance and returns whichever text
  /// color (white or black) gives better contrast, so initials stay
  static Color avatarTextColorFor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? const Color(0xFF1A1A1A)
        : Colors.white;
  }
}
