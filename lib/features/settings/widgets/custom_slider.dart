import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CustomSlider extends StatelessWidget {
  const CustomSlider({
    super.key,
    required this.start,
    required this.end,
    required this.onChanged,
  });

  final double start;
  final double end;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    return RangeSlider(
      values: RangeValues(start, end),
      min: 0.0,
      max: 2.0,
      divisions: 20,
      activeColor: AppColors.purple,
      inactiveColor: AppColors.background,
      onChanged: onChanged,
    );
  }
}
