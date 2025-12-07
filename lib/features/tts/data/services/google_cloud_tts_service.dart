import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'tts_service.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

/// Google Cloud Text-to-Speech service with high-quality Neural2 voices
/// Falls back to native TTS if Google Cloud is not configured
class GoogleCloudTtsService {
  static final GoogleCloudTtsService _instance = GoogleCloudTtsService._internal();
  factory GoogleCloudTtsService() => _instance;
  GoogleCloudTtsService._internal();

  final NativeTtsService _nativeTts = NativeTtsService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  String? _googleApiKey;
  bool _isGoogleTtsEnabled = false;
  bool _isInitialized = false;

  /// Initialize the service
  /// Attempts to load Google Cloud API key, falls back to native TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to load Google Cloud API key from assets
      await _loadGoogleCloudApiKey();
    } catch (e) {
      LoggerService.debug('Google Cloud TTS not available, using native TTS: $e');
    }

    // Always initialize native TTS as fallback
    await _nativeTts.initialize();
    _isInitialized = true;
  }

  /// Load Google Cloud API key from assets
  Future<void> _loadGoogleCloudApiKey() async {
    try {
      LoggerService.debug('Attempting to load Google Cloud API key...');
      final apiKey = await rootBundle.loadString('assets/google_tts_api_key.txt');
      _googleApiKey = apiKey.trim();
      _isGoogleTtsEnabled = _googleApiKey!.isNotEmpty;
      if (_isGoogleTtsEnabled) {
        LoggerService.info('Google Cloud TTS enabled');
      } else {
        LoggerService.warning('API key file exists but is empty');
      }
    } catch (e) {
      _isGoogleTtsEnabled = false;
      LoggerService.debug('Google Cloud TTS not configured, using native TTS fallback');
    }
  }

  /// Speak text using the best available TTS engine
  Future<void> speak(String text, String languageCode) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isGoogleTtsEnabled && _googleApiKey != null) {
      try {
        await _speakWithGoogleCloud(text, languageCode);
      } catch (e) {
        LoggerService.error('Google Cloud TTS error, falling back to native', e);
        await _nativeTts.speak(text, languageCode);
      }
    } else {
      await _nativeTts.speak(text, languageCode);
    }
  }

  /// Speak using Google Cloud Text-to-Speech API
  Future<void> _speakWithGoogleCloud(String text, String languageCode) async {
    final voiceName = _getGoogleVoiceName(languageCode);
    final mappedLang = _mapLanguageCode(languageCode);
    
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
        'pitch': 0,
        'speakingRate': 0.9,
      },
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final audioContent = jsonResponse['audioContent'] as String;
      final audioBytes = base64Decode(audioContent);
      await _audioPlayer.play(BytesSource(audioBytes));
    } else {
      throw Exception('Google TTS API error: ${response.statusCode}');
    }
  }

  /// Get the best Google Cloud voice name for a language
  String _getGoogleVoiceName(String languageCode) {
    final voiceMap = {
      'de': 'de-DE-Neural2-F', // Female German neural voice (high quality)
      'de-DE': 'de-DE-Neural2-F',
      'es': 'es-ES-Neural2-C',
      'fr': 'fr-FR-Neural2-C',
      'en': 'en-US-Neural2-F',
      'en-US': 'en-US-Neural2-F',
      'it': 'it-IT-Neural2-C',
      'pt': 'pt-PT-Neural2-A',
    };

    return voiceMap[languageCode.toLowerCase()] ?? '$languageCode-Standard-A';
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
    };

    return codeMap[languageCode.toLowerCase()] ?? languageCode;
  }

  /// Stop speaking
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _nativeTts.stop();
  }

  /// Set speech rate
  Future<void> setSpeechRate(double rate) async {
    await _nativeTts.setSpeechRate(rate);
  }

  /// Check if Google Cloud TTS is enabled
  bool get isGoogleTtsEnabled => _isGoogleTtsEnabled;

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
    _nativeTts.dispose();
  }
}

