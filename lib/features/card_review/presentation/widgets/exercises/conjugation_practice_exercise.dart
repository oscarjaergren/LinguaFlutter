import 'package:flutter/material.dart';
import '../../../../../shared/domain/models/card_model.dart';
import '../../../../../shared/domain/models/word_data.dart';
import '../../../domain/providers/practice_session_provider.dart';

/// Exercise widget for conjugation practice - provide correct verb form
class ConjugationPracticeExercise extends StatefulWidget {
  final CardModel card;
  final AnswerState answerState;
  final bool? currentAnswerCorrect;
  final ValueChanged<bool> onCheckAnswer;

  const ConjugationPracticeExercise({
    super.key,
    required this.card,
    required this.answerState,
    required this.currentAnswerCorrect,
    required this.onCheckAnswer,
  });

  @override
  State<ConjugationPracticeExercise> createState() => _ConjugationPracticeExerciseState();
}

class _ConjugationPracticeExerciseState extends State<ConjugationPracticeExercise> {
  final _answerController = TextEditingController();
  String? _correctAnswer;
  String? _prompt;

  @override
  void initState() {
    super.initState();
    _generateConjugationPrompt();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _generateConjugationPrompt() {
    final wordData = widget.card.wordData;
    
    if (wordData is VerbData) {
      // Pick a random conjugation form to test
      final forms = <String, String>{
        if (wordData.presentDu != null) 'du (present)': wordData.presentDu!,
        if (wordData.presentEr != null) 'er/sie/es (present)': wordData.presentEr!,
        if (wordData.pastSimple != null) 'past simple': wordData.pastSimple!,
        if (wordData.pastParticiple != null) 'past participle': wordData.pastParticiple!,
      };
      
      if (forms.isNotEmpty) {
        final entry = forms.entries.toList()..shuffle();
        final selected = entry.first;
        _prompt = selected.key;
        _correctAnswer = selected.value;
      } else {
        // Fallback if no conjugations available
        _prompt = 'infinitive';
        _correctAnswer = widget.card.frontText;
      }
    } else if (wordData is NounData) {
      // Test plural or genitive
      final forms = <String, String>{
        if (wordData.plural != null) 'plural': wordData.plural!,
        if (wordData.genitive != null) 'genitive': wordData.genitive!,
      };
      
      if (forms.isNotEmpty) {
        final entry = forms.entries.toList()..shuffle();
        final selected = entry.first;
        _prompt = selected.key;
        _correctAnswer = selected.value;
      } else {
        // Fallback
        _prompt = 'nominative';
        _correctAnswer = widget.card.frontText;
      }
    } else if (wordData is AdjectiveData) {
      // Test comparative or superlative
      final forms = <String, String>{
        if (wordData.comparative != null) 'comparative': wordData.comparative!,
        if (wordData.superlative != null) 'superlative': wordData.superlative!,
      };
      
      if (forms.isNotEmpty) {
        final entry = forms.entries.toList()..shuffle();
        final selected = entry.first;
        _prompt = selected.key;
        _correctAnswer = selected.value;
      } else {
        // Fallback
        _prompt = 'base form';
        _correctAnswer = widget.card.frontText;
      }
    } else {
      // No word data - fallback to basic form
      _prompt = 'base form';
      _correctAnswer = widget.card.frontText;
    }
  }

  void _checkAnswer() {
    final userAnswer = _answerController.text.trim().toLowerCase();
    final correctAnswer = _correctAnswer!.toLowerCase();
    
    // Allow some flexibility with articles and spacing
    final isCorrect = userAnswer == correctAnswer ||
                      userAnswer == correctAnswer.replaceAll(RegExp(r'^(der|die|das|ein|eine)\s+'), '');
    
    widget.onCheckAnswer(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAnswered = widget.answerState == AnswerState.answered;

    return Column(
      children: [
        // Prompt
        Text(
          'Provide the correct form:',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        // Word and form prompt
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                widget.card.frontText,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '($_prompt)',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
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
        
        // Answer input
        TextField(
          controller: _answerController,
          enabled: !isAnswered,
          decoration: InputDecoration(
            labelText: 'Your answer',
            hintText: 'Type the correct form',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: isAnswered
                ? (widget.currentAnswerCorrect == true
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1))
                : null,
            prefixIcon: isAnswered
                ? Icon(
                    widget.currentAnswerCorrect == true
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: widget.currentAnswerCorrect == true
                        ? Colors.green
                        : Colors.red,
                  )
                : const Icon(Icons.edit),
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
          autofocus: true,
          onSubmitted: !isAnswered ? (_) => _checkAnswer() : null,
        ),
        
        const SizedBox(height: 24),
        
        // Check answer button
        if (!isAnswered)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _answerController.text.trim().isNotEmpty
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
                  _correctAnswer!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
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
