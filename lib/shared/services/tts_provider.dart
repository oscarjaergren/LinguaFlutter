import 'google_cloud_tts_service.dart';

/// Factory for providing the best available TTS service
/// Supports: Native, Google Cloud, and future providers like ElevenLabs
class TtsProvider {
  static TtsProvider? _instance;
  
  late final GoogleCloudTtsService _ttsService;

  TtsProvider._() {
    _ttsService = GoogleCloudTtsService();
  }

  factory TtsProvider() {
    _instance ??= TtsProvider._();
    return _instance!;
  }

  /// Get the TTS service
  /// Returns GoogleCloudTtsService which automatically falls back to Native
  GoogleCloudTtsService get service => _ttsService;

  /// Initialize the TTS system
  Future<void> initialize() async {
    await _ttsService.initialize();
  }

  /// Speak text in the specified language
  Future<void> speak(String text, String languageCode) async {
    await _ttsService.speak(text, languageCode);
  }

  /// Stop speaking
  Future<void> stop() async {
    await _ttsService.stop();
  }

  /// Set speech rate
  Future<void> setSpeechRate(double rate) async {
    await _ttsService.setSpeechRate(rate);
  }

  /// Check if Google Cloud TTS is enabled
  bool get isGoogleCloudEnabled => _ttsService.isGoogleTtsEnabled;

  /// Dispose resources
  void dispose() {
    _ttsService.dispose();
  }
}
