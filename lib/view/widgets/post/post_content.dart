import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

class PostContent extends StatefulWidget {
  final String content;

  const PostContent({super.key, required this.content});

  @override
  State<PostContent> createState() => _PostContentState();
}

class _PostContentState extends State<PostContent> with SingleTickerProviderStateMixin {
  late LanguageIdentifier _languageIdentifier;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String? _translatedText;
  String _detectedLanguage = '';
  bool _isTranslating = false;
  bool _showTranslation = false;

  @override
  void initState() {
    super.initState();
    _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
    _detectLanguage();
  }

  @override
  void dispose() {
    _languageIdentifier.close();
    super.dispose();
  }

  Future<void> _detectLanguage() async {
    try {
      final language = await _languageIdentifier.identifyLanguage(widget.content);
      if (mounted) {
        setState(() => _detectedLanguage = language);
        print("🌐 Detected language: $language");
      }
    } catch (e) {
      print("❌ Language detection error: $e");
    }
  }

  Future<void> _translateOnDemand() async {
    if (_detectedLanguage == 'vi' || _detectedLanguage == 'und') {
      return;
    }

    // Toggle giữa hiển thị bản dịch và bản gốc
    if (_translatedText != null) {
      setState(() => _showTranslation = !_showTranslation);
      return;
    }

    setState(() => _isTranslating = true);

    try {
      // ✅ Sử dụng OnDeviceTranslator thay vì Translator
      final translator = OnDeviceTranslator(
        sourceLanguage: _getSourceLanguage(_detectedLanguage),
        targetLanguage: TranslateLanguage.vietnamese,
      );

      final translatedText = await translator.translateText(widget.content);

      if (mounted) {
        setState(() {
          _translatedText = translatedText;
          _isTranslating = false;
          _showTranslation = true;
        });
        print("✓ Translated: $translatedText");
      }

      translator.close();
    } catch (e) {
      print("❌ Translation error: $e");
      if (mounted) {
        setState(() => _isTranslating = false);
      }
    }
  }

  TranslateLanguage _getSourceLanguage(String languageCode) {
    switch (languageCode) {
      case 'en':
        return TranslateLanguage.english;
      case 'zh':
        return TranslateLanguage.chinese;
      case 'ja':
        return TranslateLanguage.japanese;
      case 'ko':
        return TranslateLanguage.korean;
      case 'fr':
        return TranslateLanguage.french;
      case 'de':
        return TranslateLanguage.german;
      case 'es':
        return TranslateLanguage.spanish;
      case 'ru':
        return TranslateLanguage.russian;
      case 'ar':
        return TranslateLanguage.arabic;
      case 'pt':
        return TranslateLanguage.portuguese;
      case 'it':
        return TranslateLanguage.italian;
      case 'th':
        return TranslateLanguage.thai;
      case 'hi':
        return TranslateLanguage.hindi;
      default:
        return TranslateLanguage.english;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.isEmpty) {
      return const SizedBox.shrink();
    }

    final isNotVietnamese = _detectedLanguage.isNotEmpty &&
        _detectedLanguage != 'vi' &&
        _detectedLanguage != 'und';

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _showTranslation ? (_translatedText ?? widget.content) : widget.content,
            style: const TextStyle(fontSize: 16),
          ),

          if (isNotVietnamese)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _isTranslating
                  ? const Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Đang dịch...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: _translateOnDemand,
                      child: Text(
                        _showTranslation ? ' Ẩn bản dịch' : ' Xem bản dịch',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}