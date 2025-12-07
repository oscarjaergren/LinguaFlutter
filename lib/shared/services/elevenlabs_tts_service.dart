import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'tts_service.dart';
import 'logger_service.dart';

/// ElevenLabs Text-to-Speech service with ultra-realistic AI voices
/// Falls back to native TTS if ElevenLabs is not configured
class ElevenLabsTtsService {
  static final ElevenLabsTtsService _instance = ElevenLabsTtsService._internal();
  factory ElevenLabsTtsService() => _instance;
  ElevenLabsTtsService._internal();

  final NativeTtsService _nativeTts = NativeTtsService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  String? _elevenLabsApiKey;
  bool _isElevenLabsEnabled = false;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadElevenLabsApiKey();
    } catch (e) {
      LoggerService.debug('ElevenLabs TTS not available, using native TTS');
    }

    await _nativeTts.initialize();
    _isInitialized = true;
  }

  /// Load ElevenLabs API key from assets
  Future<void> _loadElevenLabsApiKey() async {
    try {
      final apiKey = await rootBundle.loadString('assets/elevenlabs_api_key.txt');
      _elevenLabsApiKey = apiKey.trim();
      _isElevenLabsEnabled = _elevenLabsApiKey!.isNotEmpty;
      if (_isElevenLabsEnabled) {
        LoggerService.info('ElevenLabs TTS enabled');
      } else {
        LoggerService.warning('ElevenLabs API key file exists but is empty');
      }
    } catch (e) {
      _isElevenLabsEnabled = false;
      LoggerService.debug('ElevenLabs TTS not configured, using native TTS fallback');
    }
  }

  /// Speak text using the best available TTS engine
  Future<void> speak(String text, String languageCode) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isElevenLabsEnabled && _elevenLabsApiKey != null) {
      try {
        await _speakWithElevenLabs(text, languageCode);
      } catch (e) {
        LoggerService.error('ElevenLabs TTS error, falling back to native', e);
        await _nativeTts.speak(text, languageCode);
      }
    } else {
      await _nativeTts.speak(text, languageCode);
    }
  }

  /// Speak using ElevenLabs Text-to-Speech API
  Future<void> _speakWithElevenLabs(String text, String languageCode) async {
    final voiceId = _getElevenLabsVoiceId(languageCode);
    
    final url = Uri.parse(
      'https://api.elevenlabs.io/v1/text-to-speech/$voiceId'
    );
    
    final body = jsonEncode({
      'text': text,
      'model_id': 'eleven_multilingual_v2',
      'voice_settings': {
        'stability': 0.5,
        'similarity_boost': 0.75,
        'style': 0.0,
        'use_speaker_boost': true,
      },
    });

    final response = await http.post(
      url,
      headers: {
        'Accept': 'audio/mpeg',
        'Content-Type': 'application/json',
        'xi-api-key': _elevenLabsApiKey!,
      },
      body: body,
    );
    
    if (response.statusCode == 200) {
      final audioBytes = response.bodyBytes;
      await _audioPlayer.play(BytesSource(audioBytes));
    } else {
      throw Exception('ElevenLabs TTS API error: ${response.statusCode}');
    }
  }

  /// Get the best ElevenLabs voice ID for a language
  /// These are high-quality multilingual voices
  String _getElevenLabsVoiceId(String languageCode) {
    final voiceMap = {
      // German voices
      'de': 'pNInz6obpgDQGcFmaJgB', // Adam - multilingual male
      'de-DE': 'pNInz6obpgDQGcFmaJgB',
      
      // English voices
      'en': 'EXAVITQu4vr4xnSDxMaL', // Bella - multilingual female
      'en-US': 'EXAVITQu4vr4xnSDxMaL',
      
      // Spanish voices
      'es': 'ThT5KcBeYPX3keUQqHPh', // Dorothy - multilingual
      'es-ES': 'ThT5KcBeYPX3keUQqHPh',
      
      // French voices
      'fr': 'pNInz6obpgDQGcFmaJgB', // Adam works well for French too
      'fr-FR': 'pNInz6obpgDQGcFmaJgB',
    };

    // Default to Adam (great multilingual voice)
    return voiceMap[languageCode.toLowerCase()] ?? 'pNInz6obpgDQGcFmaJgB';
  }

  /// Stop speaking
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _nativeTts.stop();
  }

  /// Set speech rate (not applicable to ElevenLabs, uses native fallback)
  Future<void> setSpeechRate(double rate) async {
    await _nativeTts.setSpeechRate(rate);
  }

  /// Check if ElevenLabs TTS is enabled
  bool get isElevenLabsEnabled => _isElevenLabsEnabled;

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
    _nativeTts.dispose();
  }
}
