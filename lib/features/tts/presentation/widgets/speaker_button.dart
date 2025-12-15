import 'package:flutter/material.dart';
import 'package:lingua_flutter/features/tts/tts.dart';

/// A button that speaks text when pressed using text-to-speech
/// Uses Google Cloud TTS Neural2 voices if configured, falls back to native TTS
class SpeakerButton extends StatefulWidget {
  /// Factory for creating the TTS service. Overridable in tests.
  static GoogleCloudTtsService Function() ttsFactory =
      GoogleCloudTtsService.new;

  final String text;
  final String languageCode;
  final double size;
  final Color? color;
  final bool showLabel;
  
  /// If true, automatically speaks the text when the widget appears
  /// or when the text changes
  final bool autoPlay;

  const SpeakerButton({
    super.key,
    required this.text,
    required this.languageCode,
    this.size = 40,
    this.color,
    this.showLabel = false,
    this.autoPlay = false,
  });

  @override
  State<SpeakerButton> createState() => _SpeakerButtonState();
}

class _SpeakerButtonState extends State<SpeakerButton>
    with SingleTickerProviderStateMixin {
  late final GoogleCloudTtsService _ttsService =
      SpeakerButton.ttsFactory();
  bool _isSpeaking = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _ttsService.initialize();
    
    // Auto-play on first appearance if enabled
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _speak();
      });
    }
  }

  @override
  void didUpdateWidget(SpeakerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-play when text changes if enabled
    if (widget.autoPlay && oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _speak();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _speak() async {
    if (_isSpeaking) {
      await _ttsService.stop();
      setState(() => _isSpeaking = false);
      _animationController.reverse();
    } else {
      setState(() => _isSpeaking = true);
      _animationController.forward();
      
      try {
        await _ttsService.speak(widget.text, widget.languageCode);
      } finally {
        if (mounted) {
          setState(() => _isSpeaking = false);
          _animationController.reverse();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? Theme.of(context).primaryColor;

    if (widget.showLabel) {
      return OutlinedButton.icon(
        onPressed: _speak,
        icon: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_animationController.value * 0.2),
              child: Icon(
                _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                size: 20,
                color: buttonColor,
              ),
            );
          },
        ),
        label: const Text('Pronounce'),
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(color: buttonColor),
        ),
      );
    }

    return IconButton(
      onPressed: _speak,
      icon: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_animationController.value * 0.2),
            child: Icon(
              _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
              size: widget.size,
              color: buttonColor,
            ),
          );
        },
      ),
      tooltip: 'Pronounce',
    );
  }
}
