import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ImageProcessingAiResult extends StatefulWidget {
  final String title;
  final File imageFile;

  const ImageProcessingAiResult({
    super.key,
    required this.title,
    required this.imageFile,
  });

  @override
  State<ImageProcessingAiResult> createState() =>
      _ImageProcessingAiResultState();
}

class _ImageProcessingAiResultState extends State<ImageProcessingAiResult> {
  bool _isLoading = true;
  String _resultText = "";

  @override
  void initState() {
    super.initState();
    _processImageWithAI();
  }

  // ─── AI Processing Logic ─────────────────────────────────────────────
  Future<void> _processImageWithAI() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final apiKey = prefs.getString("apiKey") ?? "";
      final model = prefs.getString("model") ?? "llama-3.3-70b-versatile";
      final provider = prefs.getString("provider") ?? "groq";
      final systemPrompt = prefs.getString("systemPrompt") ?? "";
      final maxTokens = prefs.getInt("maxTokens") ?? 1000;

      if (apiKey.isEmpty) {
        setState(() {
          _resultText = "❌ API Key nai. Settings e giye set koro.";
          _isLoading = false;
        });
        return;
      }

      // Feature-wise prompt
      String prompt = "";
      switch (widget.title) {
        case "Math Problem Solver":
          prompt = "Solve this math problem step by step.";
          break;
        case "Medical Report Summarize":
          prompt = "Summarize this medical report simply.";
          break;
        case "Skin Issue Detection":
          prompt = "Analyze skin condition.";
          break;
        case "Image to Text":
          prompt = "Extract all text.";
          break;
        case "Plant & Disease Identifier":
          prompt = "Identify plant and disease.";
          break;
        default:
          prompt = "Analyze image.";
      }

      final bytes = await widget.imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // ── API endpoint নির্ধারণ করো provider অনুযায়ী ──
      String apiUrl;
      Map<String, String> headers;
      Map<String, dynamic> body;

      if (provider == "groq") {
        // Groq OpenAI-compatible endpoint
        apiUrl = "https://api.groq.com/openai/v1/chat/completions";
        headers = {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        };
        body = {
          "model": model,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {
              "role": "user",
              "content": [
                {"type": "text", "text": prompt},
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:image/jpeg;base64,$base64Image"
                  }
                }
              ]
            }
          ],
          "max_tokens": maxTokens,
        };
      } else if (provider == "grok") {
        apiUrl = "https://api.x.ai/v1/chat/completions";
        headers = {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        };
        body = {
          "model": model,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {
              "role": "user",
              "content": [
                {"type": "text", "text": prompt},
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:image/jpeg;base64,$base64Image"
                  }
                }
              ]
            }
          ],
          "max_tokens": maxTokens,
        };
      } else {
        // অন্য provider এর জন্য fallback
        setState(() {
          _resultText = "❌ Provider টি এখনো support করা হয়নি।";
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        setState(() {
          _resultText = "❌ Error ${response.statusCode}: ${data['error']?['message'] ?? 'Unknown error'}";
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _resultText = data["choices"]?[0]?["message"]?["content"] ?? "No response";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultText = "Error: $e";
        _isLoading = false;
      });
    }
  }

  // ─── Colors and Gradients (From Figma) ──────────────────────────────
  static const Color kBackground = Color(0xFF2E3149);
  static const Color kPurple = Color(0xFFA575F2);

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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Uploaded Image
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          widget.imageFile,
                          width: 277,
                          height: 254,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Summarize Label
                    const Text(
                      'Summarize:',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // AI Result Text or Loader
                    _isLoading
                        ? const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: kPurple,
                        ),
                      ),
                    )
                        : Text(
                      _resultText,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                        height: 1.3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Custom Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_sharp,
              color: kPurple,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),

          // Gradient Title
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF7CE12B),
                        Color(0xFF68ABE9),
                        Color(0xFFA575F2),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: 25,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // AI Sparkle icon near title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4567EC), Color(0xFFB2BECE)],
                  ).createShader(bounds),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),

          // Top Right AI Button
          Container(
            width: 45,
            height: 42.75,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000), // rgba(0, 0, 0, 0.25)
                  blurRadius: 4,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF9E8CF7), Color(0xFF4121DC)],
                ).createShader(bounds),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}