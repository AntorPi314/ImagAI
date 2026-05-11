import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/image_picker_util.dart';
import '../../../database/models/history_model.dart';
import '../controllers/home_controller.dart';
import '../widgets/history_list_item.dart';
import '../widgets/tool_grid_item.dart';
import '../../../features/compression/screens/image_compression_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const HomeController _controller = HomeController();
  List<HistoryModel> _history = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _controller.getHistory();
    if (!mounted) {
      return;
    }
    setState(() => _history = history);
  }

  @override
  Widget build(BuildContext context) {
    final features = _controller.getFeatures();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _HeaderSection(),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: features
                      .map(
                        (feature) => ToolGridItem(
                          title: feature.title,
                          iconPath: feature.iconPath,
                          gradient: feature.gradient,
                          onTap: () => _onFeatureTap(context, feature),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.card,
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
                      AppStrings.historyTitle,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_history.isEmpty)
                      const Text(
                        'No History Found.',
                        style: TextStyle(color: Colors.white60),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: _history.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _history[index];
                            return HistoryListItem(
                              history: item,
                              onTap: () => _openHistoryItem(context, item),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onFeatureTap(BuildContext context, FeatureItem feature) async {
  if (feature.title == 'Image Compression') {
    _pickImageForCompression(context);
    return;
  }

  if (!feature.requiresImage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${feature.title} feature coming soon!')),
    );
    return;
  }

  _showImageSourceDialog(context, feature);
}

Future<void> _pickImageForCompression(BuildContext context) async {
  final File? imageFile = await ImagePickerUtil.pickImage(ImageSource.gallery);
  if (imageFile == null || !context.mounted) return;

  await Navigator.pushNamed(
    context,
    AppRouter.imageCompression,
    arguments: ImageCompressionArgs(imageFile: imageFile),
  );
}

  void _showImageSourceDialog(BuildContext context, FeatureItem feature) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text(
                  'Take a photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () =>
                    _pickAndNavigate(context, feature, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () =>
                    _pickAndNavigate(context, feature, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndNavigate(
    BuildContext context,
    FeatureItem feature,
    ImageSource source,
  ) async {
    final File? imageFile = await ImagePickerUtil.pickImage(source);
    if (imageFile == null || !context.mounted) {
      return;
    }

    Navigator.pop(context);
    await Navigator.pushNamed(
      context,
      AppRouter.aiToolResult,
      arguments: AiToolRouteArgs(
        title: feature.title,
        prompt: _controller.promptForTitle(feature.title),
        imageFile: imageFile,
      ),
    );
    await _loadHistory();
  }

  Future<void> _openHistoryItem(
    BuildContext context,
    HistoryModel history,
  ) async {
    final imageFile = File(history.imagePath);
    if (!imageFile.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image file ar paoa jacche na.')),
      );
      return;
    }

    await Navigator.pushNamed(
      context,
      AppRouter.aiToolResult,
      arguments: AiToolRouteArgs(
        title: history.title,
        prompt: history.prompt,
        imageFile: imageFile,
        resultText: history.resultText,
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRouter.settings),
                child: SvgPicture.asset(
                  'assets/settings.svg',
                  width: 50,
                  height: 50,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRouter.settings),
                child: const Icon(Icons.tune, color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
