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
}
