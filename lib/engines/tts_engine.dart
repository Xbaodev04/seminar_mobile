import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

/// Service for dynamic text translation & text-to-speech engine
class TtsEngine extends ChangeNotifier {
  TtsEngine._private() {
    _initTts();
  }
  static final TtsEngine instance = TtsEngine._private();

  final FlutterTts _flutterTts = FlutterTts();
  final StreamController<void> _completionController =
      StreamController<void>.broadcast();

  bool _isTranslating = false;
  bool _isSpeaking = false;
  String _translatedText = '';
  String? _lastError;

  bool get isTranslating => _isTranslating;
  bool get isSpeaking => _isSpeaking;
  String get translatedText => _translatedText;
  String? get lastError => _lastError;
  Stream<void> get onCompletion => _completionController.stream;

  void _initTts() {
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
      _completionController.add(null);
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      _lastError = msg?.toString();
      notifyListeners();
    });
  }

  /// Map language code to TTS locale tag
  String _mapTtsLocale(String code) {
    switch (code) {
      case 'vi':
        return 'vi-VN';
      case 'ja':
        return 'ja-JP';
      case 'zh':
        return 'zh-CN';
      case 'ko':
        return 'ko-KR';
      case 'en':
      default:
        return 'en-US';
    }
  }

  /// Speak text out loud using TTS in the target language
  Future<void> speak({required String text, required String targetLang}) async {
    if (text.trim().isEmpty) return;

    final ttsLocale = _mapTtsLocale(targetLang);

    try {
      await stop();
      await _flutterTts.setLanguage(ttsLocale);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(text);
      _isSpeaking = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[TtsEngine] TTS speak error: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (_) {}
  }

  /// Map language code to Google Translate language code
  String _mapTranslateCode(String code) {
    switch (code) {
      case 'vi':
        return 'vi';
      case 'ja':
        return 'ja';
      case 'zh':
        return 'zh-CN';
      case 'ko':
        return 'ko';
      case 'en':
      default:
        return 'en';
    }
  }

  /// Translates text using Google Translate free endpoint
  Future<String> translateText({
    required String text,
    required String targetLang,
  }) async {
    if (text.trim().isEmpty) return text;

    final target = _mapTranslateCode(targetLang);

    _isTranslating = true;
    _lastError = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$target&dt=t&q=${Uri.encodeComponent(text)}',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
          final sentences = decoded[0] as List;
          final sb = StringBuffer();
          for (final sentence in sentences) {
            if (sentence is List && sentence.isNotEmpty) {
              sb.write(sentence[0]);
            }
          }
          final result = sb.toString();
          _translatedText = result.isNotEmpty ? result : text;
          _isTranslating = false;
          notifyListeners();
          return _translatedText;
        }
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[TtsEngine] Translation error: $e');
    }

    _isTranslating = false;
    _translatedText = text;
    notifyListeners();
    return text;
  }
}
