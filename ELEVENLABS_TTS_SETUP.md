# ✨ ElevenLabs Text-to-Speech Setup

Get **ultra-realistic, human-like voices** for your German learning app!

## Why ElevenLabs?

ElevenLabs has the **most realistic AI voices** available:

| Feature | Native | Google Cloud | **ElevenLabs** |
|---------|--------|--------------|----------------|
| Quality | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐⭐ |
| Realism | Robotic | Natural | **Human-like** |
| Emotion | ❌ | ❌ | ✅ |
| Cost | Free | ~$16/1M chars | $5-22/month |

## Setup (5 minutes)

### 1. Get an ElevenLabs API Key

1. Go to [ElevenLabs](https://elevenlabs.io/)
2. Sign up (free tier: 10,000 chars/month)
3. Go to **Profile** → **API Keys**
4. Click **Generate API Key**
5. Copy the key (looks like: `sk_...`)

### 2. Add API Key to Your App

Create a file: `assets/elevenlabs_api_key.txt`

```
your-api-key-here
```

### 3. Test It!

1. Run the app
2. Go to **Debug Menu**
3. Click **"ElevenLabs (Ultra-Realistic)"** button
4. Listen to the difference! 🤯

## Pricing

### Free Tier
- **10,000 characters/month** (about 300-400 words)
- Perfect for testing and light use
- No credit card required

### Paid Plans
- **Starter**: $5/month (30k characters)
- **Creator**: $22/month (100k characters)
- **Pro**: $99/month (500k characters)

**For learning**: ~5 words/day = ~150 chars = FREE tier covers you!

## Voice Quality

ElevenLabs uses **cutting-edge AI models** trained on real human voices:

- ✅ **Natural intonation**: Sounds genuinely human
- ✅ **Emotional range**: Can express emphasis and tone
- ✅ **Multilingual**: Excellent German pronunciation
- ✅ **Consistency**: Same voice every time

### Default Voice
The app uses **Adam** - a high-quality multilingual male voice that sounds incredibly natural.

## Security Notes

⚠️ **Keep your API key secure!**

- ✅ Already added to `.gitignore`
- ✅ Won't be committed to Git
- ❌ **Never share API keys publicly**

## Comparison

Try all three in the Debug Menu:

1. **Native** (Orange) - Basic, robotic
2. **Google** (Green) - Natural, professional
3. **ElevenLabs** (Purple) - Ultra-realistic, human-like

The difference is **dramatic**! 🎙️

---

**Note**: You can use multiple providers - the app will automatically fall back to Native TTS if ElevenLabs isn't configured.

Need help? Check the [ElevenLabs docs](https://docs.elevenlabs.io/)
