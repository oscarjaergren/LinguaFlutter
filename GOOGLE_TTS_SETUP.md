# 🎙️ Google Cloud Text-to-Speech Setup

Upgrade from robotic native TTS to **high-quality Neural2 voices** for much better pronunciation!

## Why Upgrade?

- **Native TTS** (current): Robotic, poor quality ⭐⭐
- **Google Cloud TTS**: Natural-sounding, Neural2 voices ⭐⭐⭐⭐⭐

### Voice Quality Comparison
- **German Native**: Sounds mechanical
- **Google Neural2**: Natural, human-like pronunciation

## Setup (5 minutes)

### 1. Get a Google Cloud API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or use existing)
3. Enable **Cloud Text-to-Speech API**:
   - Go to **APIs & Services** > **Library**
   - Search for "Text-to-Speech"
   - Click **Enable**
4. Create an API Key:
   - Go to **APIs & Services** > **Credentials**
   - Click **Create Credentials** > **API Key**
   - Copy the API key

### 2. Add API Key to Your App

Create a file: `assets/google_tts_api_key.txt`

```
your-api-key-here
```

### 3. Update pubspec.yaml

Add the asset (already done):
```yaml
assets:
  - assets/google_tts_api_key.txt
```

### 4. Run `flutter pub get`

```bash
flutter pub get
```

### 5. Test It!

The app will automatically detect the API key and use Google Cloud TTS with Neural2 voices!

## Pricing

**Very affordable for learning apps:**

- **Free tier**: 1 million characters/month (WaveNet voices)
- **Standard**: $4 per 1 million characters
- **Neural2**: $16 per 1 million characters (best quality)

**Example**: 10,000 German words ≈ 100,000 characters ≈ $1.60/month

## Fallback Behavior

The app intelligently falls back:
- ✅ **API key present**: Uses Google Cloud Neural2 voices
- ❌ **No API key**: Uses native TTS (free, works offline)

## Best Voices for German

The app uses **`de-DE-Neural2-F`** (female) by default for German - one of the best available!

Other options in the code:
- `de-DE-Neural2-B` (male)
- `de-DE-Neural2-C` (female, alternative)
- `de-DE-Neural2-D` (male, alternative)

## Security Notes

⚠️ **Keep your API key secure!**

- ✅ Add `assets/google_tts_api_key.txt` to `.gitignore`
- ✅ Don't commit the API key to Git
- ✅ Consider using Environment Variables for production

## Alternative: Run Without Google Cloud

The app works perfectly fine with native TTS (no setup required). Google Cloud is optional for better quality!

---

Need help? Check the [Google Cloud TTS docs](https://cloud.google.com/text-to-speech/docs)
