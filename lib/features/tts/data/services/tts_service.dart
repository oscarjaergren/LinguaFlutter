import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

/// Service for native platform text-to-speech functionality
class NativeTtsService {
  static final NativeTtsService _instance = NativeTtsService._internal();
  factory NativeTtsService() => _instance;
  NativeTtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  String? _currentLanguage;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Initialize the TTS service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure TTS settings
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.45); // Slightly slower for learning
      await _flutterTts.setPitch(1.0);

      // iOS-specific settings (not available on web)
      if (_isIOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }

      _isInitialized = true;
    } catch (e) {
      LoggerService.error('TTS initialization error', e);
    }
  }

  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages ?? []);
    } catch (e) {
      LoggerService.error('Error getting languages', e);
      return [];
    }
  }

  /// Speak text in the specified language
  /// 
  /// [text] - The text to speak
  /// [languageCode] - ISO language code (e.g., 'de-DE', 'es-ES', 'fr-FR')
  Future<void> speak(String text, String languageCode) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Set language if different from current
      if (_currentLanguage != languageCode) {
        final fullLanguageCode = _mapLanguageCode(languageCode);
        await _flutterTts.setLanguage(fullLanguageCode);
        _currentLanguage = fullLanguageCode;
      }

      await _flutterTts.speak(text);
    } catch (e) {
      LoggerService.error('Error speaking', e);
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      LoggerService.error('Error stopping speech', e);
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      LoggerService.error('Error pausing speech', e);
    }
  }

  /// Check if currently speaking (not reliably implemented by flutter_tts)
  /// This is a placeholder - the package doesn't provide a reliable way to check speaking status
  Future<bool> isSpeaking() async {
    // Note: flutter_tts doesn't provide a reliable isSpeaking method
    // Tracking would need to be done manually with completion callbacks
    return false;
  }

  /// Set speech rate (0.0 to 1.0, default 0.45 for learning)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
    } catch (e) {
      LoggerService.error('Error setting speech rate', e);
    }
  }

  /// Map simplified language codes to full locale codes
  String _mapLanguageCode(String languageCode) {
    final codeMap = {
      'de': 'de-DE', // German
      'es': 'es-ES', // Spanish
      'fr': 'fr-FR', // French
      'it': 'it-IT', // Italian
      'pt': 'pt-PT', // Portuguese
      'ru': 'ru-RU', // Russian
      'ja': 'ja-JP', // Japanese
      'zh': 'zh-CN', // Chinese (Simplified)
      'ko': 'ko-KR', // Korean
      'ar': 'ar-SA', // Arabic
      'hi': 'hi-IN', // Hindi
      'nl': 'nl-NL', // Dutch
      'sv': 'sv-SE', // Swedish
      'no': 'nb-NO', // Norwegian
      'da': 'da-DK', // Danish
      'fi': 'fi-FI', // Finnish
      'pl': 'pl-PL', // Polish
      'tr': 'tr-TR', // Turkish
      'el': 'el-GR', // Greek
      'cs': 'cs-CZ', // Czech
      'hu': 'hu-HU', // Hungarian
      'ro': 'ro-RO', // Romanian
      'th': 'th-TH', // Thai
      'vi': 'vi-VN', // Vietnamese
      'id': 'id-ID', // Indonesian
      'en': 'en-US', // English (US)
      'en-gb': 'en-GB', // English (UK)
    };

    return codeMap[languageCode.toLowerCase()] ?? languageCode;
  }

  /// Dispose resources
  void dispose() {
    _flutterTts.stop();
  }
}
