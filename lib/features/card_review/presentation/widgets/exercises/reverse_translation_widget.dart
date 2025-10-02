import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../shared/shared.dart';
import '../../../domain/providers/exercise_session_provider.dart';
import '../exercise_stats_widget.dart';

/// Reverse Translation Exercise: Translate from native to target language
class ReverseTranslationWidget extends StatefulWidget {
  const ReverseTranslationWidget({super.key});

  @override
  State<ReverseTranslationWidget> createState() => _ReverseTranslationWidgetState();
}

class _ReverseTranslationWidgetState extends State<ReverseTranslationWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasSubmitted = false;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _checkAnswer(ExerciseSessionProvider provider) {
    final card = provider.currentCard;
    if (card == null) return;

    final userAnswer = _controller.text.trim().toLowerCase();
    final correctAnswer = card.frontText.trim().toLowerCase();
    
    // For German, allow answer with or without article
    bool isCorrect;
    if (card.germanArticle != null) {
      final answerWithArticle = '${card.germanArticle} ${card.frontText}'.toLowerCase();
      isCorrect = userAnswer == correctAnswer || userAnswer == answerWithArticle;
    } else {
      isCorrect = userAnswer == correctAnswer;
    }

    setState(() {
      _hasSubmitted = true;
      _isCorrect = isCorrect;
    });
  }

  void _submitResult(ExerciseSessionProvider provider, bool overrideCorrect) {
    provider.submitAnswer(isCorrect: overrideCorrect);
    _controller.clear();
    _hasSubmitted = false;
    _isCorrect = null;
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseSessionProvider>(
      builder: (context, provider, child) {
        final card = provider.currentCard;
        if (card == null) return const SizedBox.shrink();

        return Column(
          children: [
            const SizedBox(height: 24),
            _buildExerciseBadge(context),
            const SizedBox(height: 8),
            // Stats display
            if (provider.currentExerciseType != null)
              ExerciseStatsWidget(
                card: card,
                currentExerciseType: provider.currentExerciseType!,
              ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Translate to the target language:',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Icon if available
                    if (card.icon != null) ...[
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: IconifyIcon(
                              icon: card.icon!,
                              size: 60,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Back text (native language - showing what to translate)
                    Text(
                      card.backText,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Input field
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !_hasSubmitted,
                      decoration: InputDecoration(
                        hintText: 'Type your translation...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _hasSubmitted
                            ? (_isCorrect! ? Colors.green[50] : Colors.red[50])
                            : null,
                        prefixIcon: _hasSubmitted
                            ? Icon(
                                _isCorrect! ? Icons.check_circle : Icons.cancel,
                                color: _isCorrect! ? Colors.green : Colors.red,
                              )
                            : null,
                      ),
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                      onSubmitted: (_) => !_hasSubmitted ? _checkAnswer(provider) : null,
                    ),
                    if (_hasSubmitted && !_isCorrect!) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.blue.withValues(alpha: 0.15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.blue.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Correct answer:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (card.germanArticle != null) ...[
                                Text(
                                  '${card.germanArticle!} ${card.frontText}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[300],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ] else ...[
                                Text(
                                  card.frontText,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[300],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _buildActionButtons(provider),
          ],
        );
      },
    );
  }

  Widget _buildExerciseBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.swap_horiz,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Reverse Translation',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ExerciseSessionProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: !_hasSubmitted
          ? ElevatedButton.icon(
              onPressed: () => _checkAnswer(provider),
              icon: const Icon(Icons.check),
              label: const Text('Check Answer'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : Column(
              children: [
                // Override buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _submitResult(provider, false),
                        icon: const Icon(Icons.close),
                        label: const Text('Mark Wrong'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _submitResult(provider, true),
                        icon: const Icon(Icons.check),
                        label: const Text('Mark Correct'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isCorrect! ? 'Auto-validated as correct' : 'Auto-validated as incorrect',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
    );
  }
}
