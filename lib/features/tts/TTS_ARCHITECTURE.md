# 🎙️ TTS Service Architecture

Clean, extensible architecture for multiple Text-to-Speech providers.

## Current Structure

```
services/
├── tts_service.dart             # NativeTtsService (flutter_tts)
├── enhanced_tts_service.dart    # GoogleCloudTtsService 
├── tts_provider.dart            # Factory/Provider pattern
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

## Architecture Benefits

✅ **Single Responsibility**: Each service handles one TTS provider
✅ **Extensible**: Add new providers without changing existing code  
✅ **Fallback**: All services can fallback to native TTS
✅ **Testable**: Easy to mock and test each service
✅ **Type-Safe**: Clear service names (not "Enhanced")

## Service Naming Convention

- **`NativeTtsService`**: Platform TTS (iOS/Android/Web)
- **`GoogleCloudTtsService`**: Google Cloud TTS API

## Quality Comparison

| Service | Quality | Cost | Offline | Setup |
|---------|---------|------|---------|-------|
| Native | ⭐⭐ | Free | ✅ | None |
| Google Cloud | ⭐⭐⭐⭐⭐ | ~$16/1M | ❌ | API key |

