import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── AI Provider Model ────────────────────────────────────────────────────────

enum AIProvider {
  groq('Groq', 'Groq'),
  grok('Grok', 'xAI'),
  gemini('Gemini', 'Google'),
  chatgpt('ChatGPT', 'OpenAI'),
  claude('Claude', 'Anthropic'),
  deepseek('DeepSeek', 'DeepSeek'),
  mistral('Mistral', 'Mistral AI');

  const AIProvider(this.displayName, this.company);
  final String displayName;
  final String company;
}

// ─── Model Lists per Provider ─────────────────────────────────────────────────

const Map<AIProvider, List<String>> kModelOptions = {
  AIProvider.groq: [
    'meta-llama/llama-4-scout-17b-16e-instruct',
    'meta-llama/llama-4-maverick-17b-128e-instruct',
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'gemma2-9b-it',
    'mixtral-8x7b-32768',
  ],
  AIProvider.grok: ['grok-3', 'grok-3-mini', 'grok-2', 'grok-2-mini', 'grok-beta'],
  AIProvider.gemini: [
    'gemini-2.5-pro',
    'gemini-2.0-flash',
    'gemini-1.5-pro',
    'gemini-1.5-flash',
    'gemini-1.0-pro'
  ],
  AIProvider.chatgpt: ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-3.5-turbo'],
  AIProvider.claude: [
    'claude-opus-4-5',
    'claude-sonnet-4-5',
    'claude-haiku-4-5',
    'claude-3-opus',
    'claude-3-haiku'
  ],
  AIProvider.deepseek: ['deepseek-chat', 'deepseek-reasoner'],
  AIProvider.mistral: ['mistral-large', 'mistral-medium', 'mistral-small', 'open-mistral-7b'],
};

// ─── Settings Data Class ──────────────────────────────────────────────────────
class AppSettings {
  AIProvider selectedProvider;
  String apiKey;
  String selectedModel;
  double temperatureMin;
  double temperatureMax;
  int maxOutputTokens;
  String systemPrompt;

  AppSettings({
    this.selectedProvider = AIProvider.groq,
    this.apiKey = '',
    this.selectedModel = 'meta-llama/llama-4-scout-17b-16e-instruct',
    this.temperatureMin = 0.0,
    this.temperatureMax = 1.0,
    this.maxOutputTokens = 1000,
    this.systemPrompt = '',
  });
}

// ─── Settings Page ────────────────────────────────────────────────────────────

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppSettings _settings = AppSettings();

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  final TextEditingController _maxTokensController =
  TextEditingController(text: '1000');

  bool _apiKeyVisible = false;

  // Colors
  static const Color kBackground = Color(0xFF2E3149);
  static const Color kCard = Color(0xFF252A41);
  static const Color kPurple = Color(0xFFA575F2);
  static const Color kGreen = Color(0xFF7CE12B);
  static const Color kBlue = Color(0xFF68ABE9);

  @override
  void dispose() {
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<String> get _currentModels => kModelOptions[_settings.selectedProvider]!;

  void _onProviderChanged(AIProvider? provider) {
    if (provider == null) return;
    setState(() {
      _settings.selectedProvider = provider;
      _settings.selectedModel = kModelOptions[provider]!.first;
      _apiKeyController.clear();
      _settings.apiKey = '';
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
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
                    _buildSaveButton(),
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

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kGreen, kBlue, kPurple],
                ).createShader(bounds),
                child: const Icon(Icons.arrow_back_sharp,
                    color: Colors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kGreen, kBlue, kPurple],
            ).createShader(bounds),
            child: const Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          // AI Provider chip
          _buildProviderDropdown(),
        ],
      ),
    );
  }

  Widget _buildProviderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 4)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AIProvider>(
          value: _settings.selectedProvider,
          dropdownColor: kCard,
          iconEnabledColor: Colors.white54,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          isDense: true,
          items: AIProvider.values
              .map((p) => DropdownMenuItem(
            value: p,
            child: Text('AI: ${p.displayName}'),
          ))
              .toList(),
          onChanged: _onProviderChanged,
        ),
      ),
    );
  }

  // ── API Key ──────────────────────────────────────────────────────────────────

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
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your ${_settings.selectedProvider.displayName} API key',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => _settings.apiKey = v,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _apiKeyVisible = !_apiKeyVisible),
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

  // ── Model ────────────────────────────────────────────────────────────────────

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
              dropdownColor: kCard,
              isExpanded: true,
              iconEnabledColor: Colors.white54,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              isDense: true,
              items: _currentModels
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (m) {
                if (m != null) setState(() => _settings.selectedModel = m);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Temperature ──────────────────────────────────────────────────────────────

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
                  const Text(
                    'Min',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _miniBox(_settings.temperatureMin.toStringAsFixed(1)),
                  const Spacer(),
                  const Text(
                    'Max',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _miniBox(_settings.temperatureMax.toStringAsFixed(1)),
                ],
              ),
              RangeSlider(
                values: RangeValues(
                    _settings.temperatureMin, _settings.temperatureMax),
                min: 0.0,
                max: 2.0,
                divisions: 20,
                activeColor: kPurple,
                inactiveColor: kBackground,
                onChanged: (v) => setState(() {
                  _settings.temperatureMin = v.start;
                  _settings.temperatureMax = v.end;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Max Tokens ───────────────────────────────────────────────────────────────

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
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              _miniBox(
                _settings.maxOutputTokens.toString(),
                editable: true,
                controller: _maxTokensController,
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null) _settings.maxOutputTokens = parsed;
                },
              ),
              const Spacer(),
              // Quick presets
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

  Widget _tokenPreset(int value) {
    final selected = _settings.maxOutputTokens == value;
    return GestureDetector(
      onTap: () => setState(() {
        _settings.maxOutputTokens = value;
        _maxTokensController.text = value.toString();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? kPurple.withOpacity(0.25) : kBackground,
          border: selected
              ? Border.all(color: kPurple, width: 1)
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          value >= 1000 ? '${value ~/ 1000}k' : '$value',
          style: TextStyle(
            color: selected ? kPurple : Colors.white54,
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── System Prompt ────────────────────────────────────────────────────────────

  Widget _buildSystemPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('System Prompt:'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 4)),
            ],
          ),
          child: TextField(
            controller: _systemPromptController,
            maxLines: 5,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              hintText:
              'e.g. I am a student, amake za bujanor banglay bolba.',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (v) => _settings.systemPrompt = v,
          ),
        ),
      ],
    );
  }

  // ── Save Button ───────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kGreen, kBlue, kPurple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x40A575F2), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: _saveSettings,
          child: const Text(
            'Save Settings',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("apiKey", _settings.apiKey);
    await prefs.setString("model", _settings.selectedModel);
    await prefs.setString("provider", _settings.selectedProvider.name);
    await prefs.setString("systemPrompt", _settings.systemPrompt);
    await prefs.setInt("maxTokens", _settings.maxOutputTokens);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Settings Saved ✅"),
      ),
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 18,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    ),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 4)),
      ],
    ),
    child: child,
  );

  Widget _miniBox(
      String value, {
        bool editable = false,
        TextEditingController? controller,
        ValueChanged<String>? onChanged,
      }) {
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 4)),
        ],
      ),
      child: editable && controller != null
          ? IntrinsicWidth(
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontFamily: 'Inter',
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
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
    return box;
  }
}