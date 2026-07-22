import 'package:flutter/material.dart';

class PromptTextField extends StatelessWidget {
  const PromptTextField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 5,
      style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
      decoration: const InputDecoration(
<<<<<<< HEAD
        hintText: 'e.g. Ami student, amake Banglay bujhiye bolba.',
=======
        hintText: "e.g. I'm a student, explain it to me simply.",
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: onChanged,
    );
  }
}
