import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'settings.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'image_processing_ai_result.dart';

void main() {
  runApp(const ImagAIApp());
}

class ImagAIApp extends StatelessWidget {
  const ImagAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImagAIHome(),
    );
  }
}

class ImagAIHome extends StatelessWidget {
  const ImagAIHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E3149),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderSection(),
            const SizedBox(height: 20),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: const [
                    FeatureTile(
                      title: "Math Problem Solver",
                      iconPath: "assets/svg/math.svg",
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF6189F3),
                          Color(0xFF5173CC),
                          Color(0xFF39508D),
                        ],
                        stops: [0.0, 0.3832, 1.0],
                      ),
                    ),
                    FeatureTile(
                      title: "Medical Report Summarize",
                      iconPath: "assets/svg/medical.svg",
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFCA9595),
                          Color(0xFFDC143C),
                          Color(0xFFFF7F7F),
                        ],
                        stops: [0.0144, 0.6394, 1.0],
                      ),
                    ),
                    FeatureTile(
                      title: "Skin Issue Detection",
                      iconPath: "assets/svg/skin.svg",
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE3AA39),
                          Color(0xFFE56719),
                          Color(0xFFAFEAAB),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                    FeatureTile(
                      title: "Image to Text",
                      iconPath: "assets/svg/image_ai.svg",
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF8181DD),
                          Color(0xFF4CE7AF),
                        ],
                      ),
                    ),
                    FeatureTile(
                      title: "AI PDF Viewer",
                      iconPath: "assets/svg/pdf.svg",
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
                    FeatureTile(
                      title: "Plant & Disease Identifier",
                      iconPath: "assets/svg/plant.svg",
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1E566D),
                          Color(0xFF34E89E),
                        ],
                      ),
                    ),
                    FeatureTile(
                      title: "Image Compression",
                      iconPath: "assets/svg/image_compress.svg",
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFEDCE64),
                          Color(0xFFFC506E),
                        ],
                      ),
                    ),
                    FeatureTile(
                      title: "Video Compression",
                      iconPath: "assets/svg/video_compress.svg",
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
                  ],
                ),
              ),
            ),

            const HistoryPanel(),
          ],
        ),
      ),
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Text(
                "ImagAI",
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            child: SvgPicture.asset(
              'assets/settings.svg',
              width: 50,
              height: 50,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            child: const Icon(Icons.tune, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final String title;
  final String iconPath;
  final LinearGradient gradient;

  const FeatureTile({
    super.key,
    required this.title,
    required this.iconPath,
    required this.gradient,
  });

  // ─── ইমেজ পিক করে রেজাল্ট পেজে যাওয়ার লজিক ──────────────────────────
  void _pickImageAndNavigate(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      if (context.mounted) {
        Navigator.pop(context); // বটম শিট বন্ধ করবে

        // আপনার তৈরি করা রেজাল্ট পেজে ন্যাভিগেট করবে
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageProcessingAiResult(
              title: title,
              imageFile: File(pickedFile.path),
            ),
          ),
        );
      }
    }
  }

  // ─── ক্যামেরা এবং গ্যালারি অপশন দেখানোর জন্য ডায়ালগ ─────────────────────
  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252A41), // settings.dart এর kCard কালার
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('Take a photo',
                    style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                onTap: () => _pickImageAndNavigate(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Choose from gallery',
                    style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                onTap: () => _pickImageAndNavigate(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // আপনার দেওয়া ফিচারের লিস্ট অনুযায়ী চেক করা হচ্ছে
        if (title == "Math Problem Solver" ||
            title == "Medical Report Summarize" ||
            title == "Skin Issue Detection" ||
            title == "Image to Text" ||
            title == "Plant & Disease Identifier") {
          _showImageSourceDialog(context);
        } else {
          // অন্যান্য ফিচারের জন্য সাধারণ মেসেজ (যেমন: Compression)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title feature coming soon!")),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Color(0x40000000),
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 40,
                height: 40,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF252A41),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "History",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 80,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1F6F6D),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      "https://upload.wikimedia.org/wikipedia/commons/2/29/PerfectStrawberry.jpg",
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "my image.png",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Size: 2.5 mb",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}