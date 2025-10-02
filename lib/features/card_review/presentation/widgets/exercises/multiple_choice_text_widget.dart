import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../shared/shared.dart';
import '../../../domain/providers/exercise_session_provider.dart';
import '../exercise_stats_widget.dart';

/// Multiple Choice (Text) Exercise: Select the correct translation from options
class MultipleChoiceTextWidget extends StatefulWidget {
  const MultipleChoiceTextWidget({super.key});

  @override
  State<MultipleChoiceTextWidget> createState() => _MultipleChoiceTextWidgetState();
}

class _MultipleChoiceTextWidgetState extends State<MultipleChoiceTextWidget> {
  String? _selectedAnswer;
  bool _hasSubmitted = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseSessionProvider>(
      builder: (context, provider, child) {
        final card = provider.currentCard;
        final options = provider.multipleChoiceOptions;
        
        if (card == null || options == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final correctAnswer = card.backText;
        final isCorrect = _selectedAnswer == correctAnswer;

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
                      'Select the correct translation:',
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
                    // Front text
                    Text(
                      card.frontText,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (card.germanArticle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        card.germanArticle!,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Options
                    ...options.map((option) {
                      final isSelected = _selectedAnswer == option;
                      final isThisCorrect = option == correctAnswer;
                      
                      Color? backgroundColor;
                      Color? borderColor;
                      IconData? icon;
                      
                      if (_hasSubmitted) {
                        if (isThisCorrect) {
                          backgroundColor = Colors.green[50];
                          borderColor = Colors.green;
                          icon = Icons.check_circle;
                        } else if (isSelected && !isCorrect) {
                          backgroundColor = Colors.red[50];
                          borderColor = Colors.red;
                          icon = Icons.cancel;
                        }
                      } else if (isSelected) {
                        backgroundColor = Theme.of(context).primaryColor.withValues(alpha: 0.1);
                        borderColor = Theme.of(context).primaryColor;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: _hasSubmitted
                              ? null
                              : () => setState(() => _selectedAnswer = option),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor ?? Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (icon != null) ...[
                                  Icon(
                                    icon,
                                    color: borderColor,
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Text(
                                    option,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            _buildActionButtons(provider, isCorrect),
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
            Icons.checklist,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Multiple Choice',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ExerciseSessionProvider provider, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: !_hasSubmitted
          ? ElevatedButton.icon(
              onPressed: _selectedAnswer != null
                  ? () => setState(() => _hasSubmitted = true)
                  : null,
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
                        onPressed: () {
                          provider.submitAnswer(isCorrect: false);
                          setState(() {
                            _selectedAnswer = null;
                            _hasSubmitted = false;
                          });
                        },
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
                        onPressed: () {
                          provider.submitAnswer(isCorrect: true);
                          setState(() {
                            _selectedAnswer = null;
                            _hasSubmitted = false;
                          });
                        },
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
                  isCorrect ? 'Auto-validated as correct' : 'Auto-validated as incorrect',
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
