import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'tts_service.dart';

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
      print('Google Cloud TTS not available, using native TTS: $e');
    }

    // Always initialize native TTS as fallback
    await _nativeTts.initialize();
    _isInitialized = true;
  }

  /// Load Google Cloud API key from assets
  Future<void> _loadGoogleCloudApiKey() async {
    try {
      print('🔍 [TTS DEBUG] Attempting to load Google Cloud API key...');
      // Try to load API key from assets/google_tts_api_key.txt
      final apiKey = await rootBundle.loadString('assets/google_tts_api_key.txt');
      _googleApiKey = apiKey.trim();
      _isGoogleTtsEnabled = _googleApiKey!.isNotEmpty;
      if (_isGoogleTtsEnabled) {
        print('✅ [TTS DEBUG] Google Cloud TTS enabled!');
        print('🔑 [TTS DEBUG] API Key loaded: ${_googleApiKey!.substring(0, 20)}... (${_googleApiKey!.length} chars)');
      } else {
        print('⚠️ [TTS DEBUG] API key file exists but is empty');
      }
    } catch (e) {
      _isGoogleTtsEnabled = false;
      print('❌ [TTS DEBUG] Failed to load API key: $e');
      print('ℹ️ [TTS DEBUG] Using native TTS fallback');
    }
  }

  /// Speak text using the best available TTS engine
  Future<void> speak(String text, String languageCode) async {
    if (!_isInitialized) {
      print('🔍 [TTS DEBUG] Initializing TTS service...');
      await initialize();
    }

    print('🎤 [TTS DEBUG] speak() called: "$text" (lang: $languageCode)');
    print('🔍 [TTS DEBUG] Google TTS enabled: $_isGoogleTtsEnabled, Has API key: ${_googleApiKey != null}');

    if (_isGoogleTtsEnabled && _googleApiKey != null) {
      print('✅ [TTS DEBUG] Using Google Cloud TTS');
      try {
        await _speakWithGoogleCloud(text, languageCode);
        print('✅ [TTS DEBUG] Google Cloud TTS completed successfully');
      } catch (e) {
        print('❌ [TTS DEBUG] Google Cloud TTS error: $e');
        print('🔄 [TTS DEBUG] Falling back to native TTS');
        await _nativeTts.speak(text, languageCode);
      }
    } else {
      print('🔄 [TTS DEBUG] Using native TTS (Google Cloud not configured)');
      await _nativeTts.speak(text, languageCode);
    }
  }

  /// Speak using Google Cloud Text-to-Speech API
  Future<void> _speakWithGoogleCloud(String text, String languageCode) async {
    final voiceName = _getGoogleVoiceName(languageCode);
    final mappedLang = _mapLanguageCode(languageCode);
    
    print('🔍 [TTS DEBUG] Google Cloud request:');
    print('   - Text: "$text"');
    print('   - Language: $languageCode → $mappedLang');
    print('   - Voice: $voiceName');
    
    // Prepare the request
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
        'speakingRate': 0.9, // Slightly slower for learning
      },
    });

    print('🌐 [TTS DEBUG] Making API request to Google Cloud...');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('📡 [TTS DEBUG] Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ [TTS DEBUG] API call successful, decoding audio...');
      final jsonResponse = jsonDecode(response.body);
      final audioContent = jsonResponse['audioContent'] as String;
      
      print('🔊 [TTS DEBUG] Audio size: ${audioContent.length} chars (base64)');
      
      // Decode base64 audio and play it
      final audioBytes = base64Decode(audioContent);
      print('🔊 [TTS DEBUG] Playing audio (${audioBytes.length} bytes)...');
      await _audioPlayer.play(BytesSource(audioBytes));
      print('✅ [TTS DEBUG] Audio playback started');
    } else {
      print('❌ [TTS DEBUG] API error response: ${response.body}');
      throw Exception('Google TTS API error: ${response.statusCode} - ${response.body}');
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

