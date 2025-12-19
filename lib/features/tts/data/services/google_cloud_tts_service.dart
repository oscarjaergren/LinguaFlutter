import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

/// Google Cloud Text-to-Speech service with high-quality Neural2 voices
class GoogleCloudTtsService {
  static final GoogleCloudTtsService _instance = GoogleCloudTtsService._internal();
  factory GoogleCloudTtsService() => _instance;
  GoogleCloudTtsService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  
  String? _googleApiKey;
  bool _isInitialized = false;
  bool _isEnabled = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadGoogleCloudApiKey();
    } catch (e) {
      LoggerService.error('Failed to load Google Cloud TTS API key', e);
    }

    _isInitialized = true;
  }

  /// Load Google Cloud API key from assets
  Future<void> _loadGoogleCloudApiKey() async {
    try {
      LoggerService.debug('Attempting to load Google Cloud API key...');
      final apiKey = await rootBundle.loadString('assets/google_tts_api_key.txt');
      _googleApiKey = apiKey.trim();
      _isEnabled = _googleApiKey!.isNotEmpty;
      if (_isEnabled) {
        LoggerService.info('Google Cloud TTS enabled');
      } else {
        LoggerService.warning('API key file exists but is empty');
      }
    } catch (e) {
      _isEnabled = false;
      LoggerService.error('Google Cloud TTS not configured: $e');
    }
  }

  /// Speak text using Google Cloud TTS
  Future<void> speak(String text, String languageCode) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isEnabled || _googleApiKey == null) {
      LoggerService.warning('Google Cloud TTS not configured - speech skipped');
      return;
    }

    try {
      await _speakWithGoogleCloud(text, languageCode);
    } catch (e) {
      LoggerService.error('Google Cloud TTS error', e);
    }
  }

  /// Speak using Google Cloud Text-to-Speech API with retry logic
  Future<void> _speakWithGoogleCloud(String text, String languageCode) async {
    final voiceName = _getGoogleVoiceName(languageCode);
    final mappedLang = _mapLanguageCode(languageCode);
    
    LoggerService.debug('TTS request: lang=$languageCode, mapped=$mappedLang, voice=$voiceName');
    
    final url = Uri.parse(
      'https://texttospeech.googleapis.com/v1/text:synthesize?key=$_googleApiKey'
    );
    
    final body = jsonEncode({
      'input': {'text': text},
      'voice': {
        'languageCode': mappedLang,
        'name': voiceName,
      },
      'audioConfig': {
        'audioEncoding': 'MP3',
        'pitch': 0.0,
        'speakingRate': 1.0,
      },
    });

    // Retry logic for transient network errors
    const maxRetries = 3;
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final audioContent = jsonResponse['audioContent'] as String;
          
          // Use data URL - works cross-platform without temp files
          final dataUrl = 'data:audio/mp3;base64,$audioContent';
          await _audioPlayer.play(UrlSource(dataUrl));
          return;
        } else {
          throw Exception('API error ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        LoggerService.warning('TTS attempt $attempt/$maxRetries failed: $e');
        if (attempt == maxRetries) {
          rethrow;
        }
        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  /// Get the best Google Cloud voice name for a language
  /// Uses Studio voices (highest quality) where available, falls back to Neural2
  String _getGoogleVoiceName(String languageCode) {
    // Studio voices are the highest quality (where available)
    // Neural2 voices are second-best
    final voiceMap = {
      // German - Studio voice available
      'de': 'de-DE-Studio-B',
      'de-DE': 'de-DE-Studio-B',
      // Spanish - Studio voice available
      'es': 'es-ES-Studio-C',
      'es-ES': 'es-ES-Studio-C',
      // French - Studio voice available  
      'fr': 'fr-FR-Studio-A',
      'fr-FR': 'fr-FR-Studio-A',
      // English - Studio voice available
      'en': 'en-US-Studio-O',
      'en-US': 'en-US-Studio-O',
      'en-GB': 'en-GB-Studio-B',
      // Italian - Studio voice available
      'it': 'it-IT-Studio-A',
      'it-IT': 'it-IT-Studio-A',
      // Portuguese - Neural2 (no Studio)
      'pt': 'pt-PT-Neural2-A',
      'pt-PT': 'pt-PT-Neural2-A',
      'pt-BR': 'pt-BR-Neural2-A',
      // Japanese - Neural2 (no Studio)
      'ja': 'ja-JP-Neural2-B',
      'ja-JP': 'ja-JP-Neural2-B',
      // Korean - Neural2 (no Studio)
      'ko': 'ko-KR-Neural2-A',
      'ko-KR': 'ko-KR-Neural2-A',
      // Chinese - Neural2 (no Studio)
      'zh': 'cmn-CN-Neural2-A',
      'cmn-CN': 'cmn-CN-Neural2-A',
      // Russian - Neural2 (no Studio)
      'ru': 'ru-RU-Neural2-A',
      'ru-RU': 'ru-RU-Neural2-A',
      // Dutch - Neural2 (no Studio)
      'nl': 'nl-NL-Neural2-A',
      'nl-NL': 'nl-NL-Neural2-A',
      // Polish - Neural2 (no Studio)
      'pl': 'pl-PL-Neural2-A',
      'pl-PL': 'pl-PL-Neural2-A',
      // Swedish - Neural2 (no Studio)
      'sv': 'sv-SE-Neural2-A',
      'sv-SE': 'sv-SE-Neural2-A',
    };

    return voiceMap[languageCode.toLowerCase()] ?? 
           '${_mapLanguageCode(languageCode)}-Neural2-A';
  }

  /// Map simplified language codes to full locale codes
  String _mapLanguageCode(String languageCode) {
    final codeMap = {
      'de': 'de-DE',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'it': 'it-IT',
      'pt': 'pt-PT',
      'en': 'en-US',
      'ja': 'ja-JP',
      'ko': 'ko-KR',
      'zh': 'cmn-CN',
      'ru': 'ru-RU',
      'nl': 'nl-NL',
      'pl': 'pl-PL',
      'sv': 'sv-SE',
    };

    return codeMap[languageCode.toLowerCase()] ?? languageCode;
  }

  /// Stop speaking
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  /// Check if Google Cloud TTS is enabled
  bool get isEnabled => _isEnabled;

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}

