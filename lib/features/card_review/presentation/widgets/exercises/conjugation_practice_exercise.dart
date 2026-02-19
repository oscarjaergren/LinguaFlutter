import 'package:flutter/material.dart';
import '../../../../../shared/domain/models/card_model.dart';
import '../../../../../shared/domain/models/word_data.dart';
import '../../../../tts/presentation/widgets/speaker_button.dart';
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
  State<ConjugationPracticeExercise> createState() =>
      _ConjugationPracticeExerciseState();
}

class _ConjugationPracticeExerciseState
    extends State<ConjugationPracticeExercise> {
  final _answerController = TextEditingController();
  late String _correctAnswer;
  late String _prompt;
  String? _selectedArticle;
  bool _isArticlePrompt = false;

  static const List<String> _articles = ['der', 'die', 'das'];

  @override
  void initState() {
    super.initState();
    _answerController.addListener(_onTextChanged);
    _generateConjugationPrompt();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void didUpdateWidget(ConjugationPracticeExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cardChanged = oldWidget.card.id != widget.card.id;
    final wordDataChanged = oldWidget.card.wordData != widget.card.wordData;
    final resetToNewExercise =
        oldWidget.answerState != AnswerState.pending &&
        widget.answerState == AnswerState.pending;
    if (cardChanged || wordDataChanged || resetToNewExercise) {
      _answerController.clear();
      _selectedArticle = null;
      _generateConjugationPrompt();
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _generateConjugationPrompt() {
    // Reset article-prompt flag at the start so every branch is self-contained.
    // Without this, a stale true from a previous noun card would persist when
    // the card's wordData changes without triggering didUpdateWidget's reset
    // (e.g. same card.id, same answerState — Bug 5).
    _isArticlePrompt = false;
    final wordData = widget.card.wordData;

    if (wordData is VerbData) {
      // _canDoExercise guarantees at least one conjugation field is non-null.
      final forms = <String, String>{
        if (wordData.presentDu != null) 'du (present)': wordData.presentDu!,
        if (wordData.presentEr != null)
          'er/sie/es (present)': wordData.presentEr!,
        if (wordData.pastSimple != null) 'past simple': wordData.pastSimple!,
        if (wordData.pastParticiple != null)
          'past participle': wordData.pastParticiple!,
      };
      assert(
        forms.isNotEmpty,
        'ConjugationPracticeExercise reached with VerbData that has no '
        'conjugation fields — _canDoExercise should have excluded this card.',
      );
      final entry = forms.entries.toList()..shuffle();
      final selected = entry.first;
      _prompt = selected.key;
      _correctAnswer = selected.value;
    } else if (wordData is NounData) {
      // _canDoExercise guarantees gender is non-empty.
      final gender = wordData.gender.toLowerCase().trim();
      assert(
        gender.isNotEmpty,
        'ConjugationPracticeExercise reached with NounData that has empty '
        'gender — _canDoExercise should have excluded this card.',
      );
      if (_articles.contains(gender)) {
        _prompt = 'article';
        _correctAnswer = gender;
        _isArticlePrompt = true;
      } else {
        // Non-standard gender value stored as text (e.g. "masculine").
        _prompt = 'gender';
        _correctAnswer = gender;
      }
    } else if (wordData is AdjectiveData) {
      // _canDoExercise guarantees at least one comparison form is non-null.
      final forms = <String, String>{
        if (wordData.comparative != null) 'comparative': wordData.comparative!,
        if (wordData.superlative != null) 'superlative': wordData.superlative!,
      };
      assert(
        forms.isNotEmpty,
        'ConjugationPracticeExercise reached with AdjectiveData that has no '
        'comparison forms — _canDoExercise should have excluded this card.',
      );
      final entry = forms.entries.toList()..shuffle();
      final selected = entry.first;
      _prompt = selected.key;
      _correctAnswer = selected.value;
    } else {
      // AdverbData / null / unknown — should never reach here.
      assert(
        false,
        'ConjugationPracticeExercise reached with untestable wordData '
        '(${wordData.runtimeType}) — _canDoExercise should have excluded this card.',
      );
      // Safe fallback for release builds so the widget doesn't crash.
      _prompt = 'base form';
      _correctAnswer = widget.card.frontText;
    }
  }

  void _checkAnswer() {
    final bool isCorrect;

    if (_isArticlePrompt) {
      // Check article selection
      isCorrect =
          _selectedArticle?.toLowerCase() == _correctAnswer.toLowerCase();
    } else {
      // Check text input
      final userAnswer = _answerController.text.trim().toLowerCase();
      final correctAnswer = _correctAnswer.toLowerCase();

      if (_prompt == 'gender') {
        // Gender prompt: require exact match — do not strip articles, since
        // the user is being asked for the gender value as stored.
        isCorrect = userAnswer == correctAnswer;
      } else {
        // Other text prompts: allow flexibility by ignoring a leading article.
        isCorrect =
            userAnswer == correctAnswer ||
            userAnswer ==
                correctAnswer.replaceAll(
                  RegExp(r'^(der|die|das|ein|eine)\s+'),
                  '',
                );
      }
    }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.card.frontText,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(width: 12),
                  SpeakerButton(
                    text: widget.card.frontText,
                    languageCode: widget.card.language,
                    size: 28,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ],
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

        // Article selection or text input
        if (_isArticlePrompt)
          _buildArticleSelector(context, isAnswered)
        else
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
              onPressed: _isArticlePrompt
                  ? (_selectedArticle != null ? _checkAnswer : null)
                  : (_answerController.text.trim().isNotEmpty
                        ? _checkAnswer
                        : null),
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
                  _correctAnswer,
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

  Widget _buildArticleSelector(BuildContext context, bool isAnswered) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _articles.map((article) {
        final isSelected = _selectedArticle == article;
        final articleColor = _getArticleColor(article);
        final isCorrectAnswer = article == _correctAnswer.toLowerCase();

        // Show feedback colors only after answer
        Color? backgroundColor;
        Color? borderColor;
        Color? textColor;

        if (isAnswered) {
          if (isSelected) {
            if (widget.currentAnswerCorrect == true) {
              backgroundColor = Colors.green.withValues(alpha: 0.2);
              borderColor = Colors.green;
              textColor = Colors.green;
            } else {
              backgroundColor = Colors.red.withValues(alpha: 0.2);
              borderColor = Colors.red;
              textColor = Colors.red;
            }
          }
          // Always highlight the correct answer after submission so the user
          // sees it even when _selectedArticle is null (Bug 5).
          if (isCorrectAnswer && widget.currentAnswerCorrect != true) {
            backgroundColor = Colors.green.withValues(alpha: 0.1);
            borderColor = Colors.green.withValues(alpha: 0.5);
            textColor = Colors.green;
          }
        } else if (isSelected) {
          backgroundColor = articleColor.withValues(alpha: 0.2);
          borderColor = articleColor;
          textColor = articleColor;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: backgroundColor ?? Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: !isAnswered
                    ? () => setState(() => _selectedArticle = article)
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          borderColor ??
                          (isSelected
                              ? articleColor
                              : colorScheme.outline.withValues(alpha: 0.3)),
                      width: isSelected || (isAnswered && isSelected) ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        article,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color:
                              textColor ??
                              (isSelected
                                  ? articleColor
                                  : colorScheme.onSurface),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: articleColor.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getArticleColor(String article) {
    switch (article) {
      case 'der':
        return Colors.blue;
      case 'die':
        return Colors.pink;
      case 'das':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
