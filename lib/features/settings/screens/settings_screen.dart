import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../database/models/settings_model.dart';
import '../../../shared/widgets/primary_button.dart';
import '../controllers/settings_controller.dart';
import '../widgets/custom_slider.dart';
import '../widgets/prompt_textfield.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController _controller = SettingsController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  final TextEditingController _maxTokensController = TextEditingController();

  SettingsModel _settings = const SettingsModel();
  bool _apiKeyVisible = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

<<<<<<< HEAD
  Future<void> _load() async {
    final settings = await _controller.loadSettings();
    _apiKeyController.text = settings.apiKey;
    _systemPromptController.text = settings.systemPrompt;
    _maxTokensController.text = settings.maxOutputTokens.toString();

=======
Future<void> _load() async {
  try {
    final settings = await _controller.loadSettings();
    if (!mounted) return;
    _apiKeyController.text = settings.apiKey;
    _systemPromptController.text = settings.systemPrompt;
    _maxTokensController.text = settings.maxOutputTokens.toString();
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
<<<<<<< HEAD
  }
=======
  } catch (_) {
    if (!mounted) return;
    setState(() => _isLoading = false); // spinner stops even on error
  }
}
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2

  @override
  void dispose() {
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  List<String> get _currentModels =>
      ApiConstants.modelOptions[_settings.selectedProvider]!;

  Future<void> _save() async {
    await _controller.saveSettings(_settings);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
<<<<<<< HEAD
    ).showSnackBar(const SnackBar(content: Text('Settings Saved ✅')));
=======
    ).showSnackBar(const SnackBar(content: Text('Settings Saved ')));
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              )
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildApiKeySection(),
                          const SizedBox(height: 24),
                          _buildModelSection(),
                          const SizedBox(height: 24),
                          _buildTemperatureSection(),
                          const SizedBox(height: 24),
                          _buildMaxTokensSection(),
                          const SizedBox(height: 24),
                          _buildSystemPromptSection(),
                          const SizedBox(height: 32),
                          PrimaryButton(
                            text: AppStrings.saveSettings,
                            onPressed: _save,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_sharp,
              color: AppColors.purple,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: const Text(
                AppStrings.settingsTitle,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          _buildProviderDropdown(),
        ],
      ),
    );
  }

  Widget _buildProviderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AIProvider>(
          value: _settings.selectedProvider,
          dropdownColor: AppColors.card,
          iconEnabledColor: Colors.white54,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          isDense: true,
          items: AIProvider.values
              .map(
                (provider) => DropdownMenuItem(
                  value: provider,
                  child: Text('AI: ${provider.displayName}'),
                ),
              )
              .toList(),
          onChanged: (provider) {
            if (provider == null) {
              return;
            }

            final nextSettings = _controller.onProviderChanged(
              _settings,
              provider,
            );
            _apiKeyController.clear();
            setState(() => _settings = nextSettings);
          },
        ),
      ),
    );
  }

  Widget _buildApiKeySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Api Key:'),
        const SizedBox(height: 10),
        _card(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _apiKeyController,
                  obscureText: !_apiKeyVisible,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  decoration: InputDecoration(
                    hintText:
                        'Enter your ${_settings.selectedProvider.displayName} API key',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    _settings = _settings.copyWith(apiKey: value);
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _apiKeyVisible = !_apiKeyVisible);
                },
                child: Icon(
                  _apiKeyVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Model:'),
        const SizedBox(height: 10),
        _card(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _settings.selectedModel,
              dropdownColor: AppColors.card,
              isExpanded: true,
              iconEnabledColor: Colors.white54,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              isDense: true,
              items: _currentModels
                  .map(
                    (model) =>
                        DropdownMenuItem(value: model, child: Text(model)),
                  )
                  .toList(),
              onChanged: (model) {
                if (model == null) {
                  return;
                }
                setState(() {
                  _settings = _settings.copyWith(selectedModel: model);
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Temperature:'),
        const SizedBox(height: 10),
        _card(
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Min', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 12),
                  _miniBox(_settings.temperatureMin.toStringAsFixed(1)),
                  const Spacer(),
                  const Text('Max', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 12),
                  _miniBox(_settings.temperatureMax.toStringAsFixed(1)),
                ],
              ),
              CustomSlider(
                start: _settings.temperatureMin,
                end: _settings.temperatureMax,
                onChanged: (values) {
                  setState(() {
                    _settings = _settings.copyWith(
                      temperatureMin: values.start,
                      temperatureMax: values.end,
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaxTokensSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Max Output Tokens:'),
        const SizedBox(height: 10),
        _card(
          child: Row(
            children: [
              const Text(
                'Length Control',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 12),
              _miniBox(
                _settings.maxOutputTokens.toString(),
                editable: true,
                controller: _maxTokensController,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed == null) {
                    return;
                  }
                  _settings = _settings.copyWith(maxOutputTokens: parsed);
                },
              ),
              const Spacer(),
              _tokenPreset(256),
              const SizedBox(width: 6),
              _tokenPreset(1000),
              const SizedBox(width: 6),
              _tokenPreset(4096),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('System Prompt:'),
        const SizedBox(height: 10),
        _card(
          child: PromptTextField(
            controller: _systemPromptController,
            onChanged: (value) {
              _settings = _settings.copyWith(systemPrompt: value);
            },
          ),
        ),
      ],
    );
  }

  Widget _tokenPreset(int value) {
    final isSelected = _settings.maxOutputTokens == value;
    return GestureDetector(
      onTap: () {
        _maxTokensController.text = value.toString();
        setState(() {
          _settings = _settings.copyWith(maxOutputTokens: value);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.purple.withValues(alpha: 0.25)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.purple, width: 1)
              : null,
        ),
        child: Text(
          value >= 1000 ? '${value ~/ 1000}k' : '$value',
          style: TextStyle(
            color: isSelected ? AppColors.purple : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _miniBox(
    String value, {
    bool editable = false,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: editable && controller != null
          ? IntrinsicWidth(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: onChanged,
              ),
            )
          : Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
    );
  }
}
