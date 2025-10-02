import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'tts_service.dart';

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
  /// Attempts to load ElevenLabs API key, falls back to native TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadElevenLabsApiKey();
    } catch (e) {
      print('ElevenLabs TTS not available, using native TTS: $e');
    }

    await _nativeTts.initialize();
    _isInitialized = true;
  }

  /// Load ElevenLabs API key from assets
  Future<void> _loadElevenLabsApiKey() async {
    try {
      print('🔍 [TTS DEBUG] Attempting to load ElevenLabs API key...');
      final apiKey = await rootBundle.loadString('assets/elevenlabs_api_key.txt');
      _elevenLabsApiKey = apiKey.trim();
      _isElevenLabsEnabled = _elevenLabsApiKey!.isNotEmpty;
      if (_isElevenLabsEnabled) {
        print('✅ [TTS DEBUG] ElevenLabs TTS enabled!');
        print('🔑 [TTS DEBUG] API Key loaded: ${_elevenLabsApiKey!.substring(0, 20)}... (${_elevenLabsApiKey!.length} chars)');
      } else {
        print('⚠️ [TTS DEBUG] API key file exists but is empty');
      }
    } catch (e) {
      _isElevenLabsEnabled = false;
      print('❌ [TTS DEBUG] Failed to load ElevenLabs API key: $e');
      print('ℹ️ [TTS DEBUG] Using native TTS fallback');
    }
  }

  /// Speak text using the best available TTS engine
  Future<void> speak(String text, String languageCode) async {
    if (!_isInitialized) {
      print('🔍 [TTS DEBUG] Initializing ElevenLabs TTS service...');
      await initialize();
    }

    print('🎤 [TTS DEBUG] ElevenLabs speak() called: "$text" (lang: $languageCode)');
    print('🔍 [TTS DEBUG] ElevenLabs enabled: $_isElevenLabsEnabled, Has API key: ${_elevenLabsApiKey != null}');

    if (_isElevenLabsEnabled && _elevenLabsApiKey != null) {
      print('✅ [TTS DEBUG] Using ElevenLabs TTS');
      try {
        await _speakWithElevenLabs(text, languageCode);
        print('✅ [TTS DEBUG] ElevenLabs TTS completed successfully');
      } catch (e) {
        print('❌ [TTS DEBUG] ElevenLabs TTS error: $e');
        print('🔄 [TTS DEBUG] Falling back to native TTS');
        await _nativeTts.speak(text, languageCode);
      }
    } else {
      print('🔄 [TTS DEBUG] Using native TTS (ElevenLabs not configured)');
      await _nativeTts.speak(text, languageCode);
    }
  }

  /// Speak using ElevenLabs Text-to-Speech API
  Future<void> _speakWithElevenLabs(String text, String languageCode) async {
    final voiceId = _getElevenLabsVoiceId(languageCode);
    
    print('🔍 [TTS DEBUG] ElevenLabs request:');
    print('   - Text: "$text"');
    print('   - Language: $languageCode');
    print('   - Voice ID: $voiceId');
    
    // ElevenLabs API endpoint
    final url = Uri.parse(
      'https://api.elevenlabs.io/v1/text-to-speech/$voiceId'
    );
    
    final body = jsonEncode({
      'text': text,
      'model_id': 'eleven_multilingual_v2', // Best quality multilingual model
      'voice_settings': {
        'stability': 0.5,
        'similarity_boost': 0.75,
        'style': 0.0,
        'use_speaker_boost': true,
      },
    });

    print('🌐 [TTS DEBUG] Making API request to ElevenLabs...');
    final response = await http.post(
      url,
      headers: {
        'Accept': 'audio/mpeg',
        'Content-Type': 'application/json',
        'xi-api-key': _elevenLabsApiKey!,
      },
      body: body,
    );

    print('📡 [TTS DEBUG] Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ [TTS DEBUG] API call successful');
      final audioBytes = response.bodyBytes;
      
      print('🔊 [TTS DEBUG] Audio size: ${audioBytes.length} bytes');
      print('🔊 [TTS DEBUG] Playing audio...');
      await _audioPlayer.play(BytesSource(audioBytes));
      print('✅ [TTS DEBUG] Audio playback started');
    } else {
      print('❌ [TTS DEBUG] API error response: ${response.body}');
      throw Exception('ElevenLabs TTS API error: ${response.statusCode} - ${response.body}');
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
