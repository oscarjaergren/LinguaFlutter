# 🎙️ TTS Service Architecture

Clean, extensible architecture for multiple Text-to-Speech providers.

## Current Structure

```
services/
├── tts_service.dart             # NativeTtsService (flutter_tts)
├── enhanced_tts_service.dart    # GoogleCloudTtsService 
├── tts_provider.dart            # Factory/Provider pattern
└── [future] elevenlabs_tts_service.dart
```

## Services

### **1. NativeTtsService** (`tts_service.dart`)
- Platform-native TTS (flutter_tts)
- ✅ Free
- ✅ Works offline
- ❌ Robotic quality

### **2. GoogleCloudTtsService** (`enhanced_tts_service.dart`)
- Google Cloud Neural2 voices
- ✅ High quality
- ✅ Auto-fallback to Native
- ❌ Requires API key
- ❌ Needs internet

### **3. TtsProvider** (`tts_provider.dart`)
- Singleton factory
- Provides best available TTS
- Easy to extend

## Adding New Providers (e.g., ElevenLabs)

### Step 1: Create Service Class

```dart
// elevenlabs_tts_service.dart
import 'tts_service.dart';

class ElevenLabsTtsService {
  final NativeTtsService _fallback = NativeTtsService();
  String? _apiKey;
  bool _isEnabled = false;

  Future<void> initialize() async {
    // Load ElevenLabs API key
    await _loadApiKey();
    await _fallback.initialize();
  }

  Future<void> speak(String text, String languageCode) async {
    if (_isEnabled && _apiKey != null) {
      try {
        await _speakWithElevenLabs(text, languageCode);
      } catch (e) {
        await _fallback.speak(text, languageCode);
      }
    } else {
      await _fallback.speak(text, languageCode);
    }
  }

  Future<void> _speakWithElevenLabs(String text, String lang) async {
    // ElevenLabs API implementation
  }

  // ... other methods
}
```

### Step 2: Update TtsProvider

```dart
// tts_provider.dart
import 'elevenlabs_tts_service.dart';

class TtsProvider {
  // Option A: Use ElevenLabs if configured, else Google Cloud, else Native
  TtsServiceBase _selectBestService() {
    if (hasElevenLabsKey()) return ElevenLabsTtsService();
    if (hasGoogleCloudKey()) return GoogleCloudTtsService();
    return NativeTtsService();
  }

  // Option B: Let user choose in settings
  void setPreferredProvider(TtsProviderType type) {
    switch (type) {
      case TtsProviderType.elevenLabs:
        _service = ElevenLabsTtsService();
      case TtsProviderType.googleCloud:
        _service = GoogleCloudTtsService();
      case TtsProviderType.native:
        _service = NativeTtsService();
    }
  }
}
```

### Step 3: Add to Dependencies

```yaml
# pubspec.yaml
dependencies:
  # ElevenLabs SDK (example)
  elevenlabs: ^1.0.0
```

## Architecture Benefits

✅ **Single Responsibility**: Each service handles one TTS provider
✅ **Extensible**: Add new providers without changing existing code  
✅ **Fallback**: All services can fallback to native TTS
✅ **Testable**: Easy to mock and test each service
✅ **Type-Safe**: Clear service names (not "Enhanced")

## Service Naming Convention

- **`NativeTtsService`**: Platform TTS (iOS/Android/Web)
- **`GoogleCloudTtsService`**: Google Cloud TTS API
- **`ElevenLabsTtsService`**: ElevenLabs API
- **`AzureTtsService`**: Azure Cognitive Services
- **`AwsPollyt TtsService`**: Amazon Polly

## Quality Comparison

| Service | Quality | Cost | Offline | Setup |
|---------|---------|------|---------|-------|
| Native | ⭐⭐ | Free | ✅ | None |
| Google Cloud | ⭐⭐⭐⭐⭐ | ~$16/1M | ❌ | API key |
| ElevenLabs | ⭐⭐⭐⭐⭐ | $5-22/mo | ❌ | API key |
| Azure | ⭐⭐⭐⭐⭐ | ~$16/1M | ❌ | API key |

---

**Note**: File `enhanced_tts_service.dart` should be renamed to `google_cloud_tts_service.dart` for clarity.
