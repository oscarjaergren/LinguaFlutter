import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../shared/shared.dart';
import '../../../domain/providers/exercise_session_provider.dart';
import '../exercise_stats_widget.dart';

/// Reading Recognition Exercise: See the word and recall its meaning
class ReadingRecognitionWidget extends StatelessWidget {
  const ReadingRecognitionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseSessionProvider>(
      builder: (context, provider, child) {
        final card = provider.currentCard;
        if (card == null) return const SizedBox.shrink();

        return Column(
          children: [
            const SizedBox(height: 24),
            // Exercise type badge
            _buildExerciseBadge(context),
            const SizedBox(height: 8),
            // Stats display
            if (provider.currentExerciseType != null)
              ExerciseStatsWidget(
                card: card,
                currentExerciseType: provider.currentExerciseType!,
              ),
            const SizedBox(height: 16),
            // Question card
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon if available
                      if (card.icon != null) ...[
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: IconifyIcon(
                              icon: card.icon!,
                              size: 80,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      // Front text (word to learn) with speaker button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              card.frontText,
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SpeakerButton(
                            text: card.frontText,
                            languageCode: card.language,
                            size: 32,
                          ),
                        ],
                      ),
                      if (card.germanArticle != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          card.germanArticle!,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 48),
                      // Answer section
                      if (provider.isAnswerShown) ...[
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
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  color: Colors.blue[300],
                                  size: 32,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  card.backText,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'What does this word mean?',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Action buttons
            _buildActionButtons(context, provider),
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
            Icons.book_outlined,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Reading Recognition',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ExerciseSessionProvider provider,
  ) {
    if (!provider.isAnswerShown) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton.icon(
          onPressed: () => provider.showAnswer(),
          icon: const Icon(Icons.visibility),
          label: const Text('Show Answer'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => provider.submitAnswer(isCorrect: false),
              icon: const Icon(Icons.close),
              label: const Text('Incorrect'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => provider.submitAnswer(isCorrect: true),
              icon: const Icon(Icons.check),
              label: const Text('Correct'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
