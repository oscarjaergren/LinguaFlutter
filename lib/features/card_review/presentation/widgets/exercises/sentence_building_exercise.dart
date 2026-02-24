import 'package:flutter/material.dart';
import '../../../../../shared/domain/models/card_model.dart';
import '../../../../tts/presentation/widgets/speaker_button.dart';
import '../../../domain/providers/practice_session_types.dart';

/// Exercise widget for sentence building - arrange scrambled words
class SentenceBuildingExercise extends StatefulWidget {
  final CardModel card;
  final AnswerState answerState;
  final bool? currentAnswerCorrect;
  final ValueChanged<bool> onCheckAnswer;

  const SentenceBuildingExercise({
    super.key,
    required this.card,
    required this.answerState,
    required this.currentAnswerCorrect,
    required this.onCheckAnswer,
  });

  @override
  State<SentenceBuildingExercise> createState() =>
      _SentenceBuildingExerciseState();
}

class _SentenceBuildingExerciseState extends State<SentenceBuildingExercise> {
  List<String> _availableWords = [];
  List<String> _selectedWords = [];
  String? _correctSentence;

  @override
  void initState() {
    super.initState();
    _initializeExercise();
  }

  void _initializeExercise() {
    // Use first example sentence if available, otherwise use front text
    if (widget.card.examples.isNotEmpty) {
      _correctSentence = widget.card.examples.first.trim();
    } else {
      // Fallback: use front text as sentence
      _correctSentence = widget.card.frontText.trim();
    }

    // Split into words and shuffle
    final words = _correctSentence!.split(RegExp(r'\s+'));
    _availableWords = List.from(words)..shuffle();
    _selectedWords = [];
  }

  void _selectWord(String word) {
    if (widget.answerState == AnswerState.answered) return;

    setState(() {
      _availableWords.remove(word);
      _selectedWords.add(word);
    });
  }

  void _unselectWord(String word) {
    if (widget.answerState == AnswerState.answered) return;

    setState(() {
      _selectedWords.remove(word);
      _availableWords.add(word);
    });
  }

  void _checkAnswer() {
    final userSentence = _selectedWords.join(' ');
    final isCorrect =
        userSentence.toLowerCase().trim() ==
        _correctSentence!.toLowerCase().trim();
    widget.onCheckAnswer(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAnswered = widget.answerState == AnswerState.answered;

    return Column(
      children: [
        // Prompt with speaker button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Arrange the words to form a correct sentence:',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            SpeakerButton(
              text: widget.card.frontText,
              languageCode: widget.card.language,
              size: 24,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Translation hint
        Text(
          widget.card.backText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.outline,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Selected words area (answer being built)
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAnswered
                ? (widget.currentAnswerCorrect == true
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1))
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAnswered
                  ? (widget.currentAnswerCorrect == true
                        ? Colors.green
                        : Colors.red)
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: _selectedWords.isEmpty
              ? Center(
                  child: Text(
                    'Tap words below to build your sentence',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedWords.map((word) {
                    return _WordChip(
                      word: word,
                      onTap: () => _unselectWord(word),
                      isSelected: true,
                      isEnabled: !isAnswered,
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 24),

        // Available words area
        if (_availableWords.isNotEmpty) ...[
          Text(
            'Available words:',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _availableWords.map((word) {
              return _WordChip(
                word: word,
                onTap: () => _selectWord(word),
                isSelected: false,
                isEnabled: !isAnswered,
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 24),

        // Check answer button
        if (!isAnswered)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _selectedWords.length ==
                      _correctSentence!.split(RegExp(r'\s+')).length
                  ? _checkAnswer
                  : null,
              child: const Text('Check Answer'),
            ),
          ),

        // Show correct answer if wrong
        if (isAnswered && widget.currentAnswerCorrect == false) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'Correct answer:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _correctSentence!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  final String word;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isEnabled;

  const _WordChip({
    required this.word,
    required this.onTap,
    required this.isSelected,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            word,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
