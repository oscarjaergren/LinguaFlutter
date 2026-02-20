import 'package:flutter/material.dart';
import '../../../../../shared/domain/models/card_model.dart';
import '../../../../../shared/domain/models/exercise_type.dart';
import '../../../../../shared/domain/models/word_data.dart';
import '../../../../tts/presentation/widgets/speaker_button.dart';
import '../../../domain/providers/practice_session_provider.dart';
import 'sentence_building_exercise.dart';
import 'conjugation_practice_exercise.dart';
import 'article_selection_exercise.dart';

/// Unified exercise content widget that renders the appropriate exercise
/// based on the exercise type. This is the content inside the swipeable card.
class ExerciseContentWidget extends StatefulWidget {
  final CardModel card;
  final ExerciseType exerciseType;
  final List<String>? multipleChoiceOptions;
  final AnswerState answerState;
  final bool? currentAnswerCorrect;
  final Function(bool isCorrect) onCheckAnswer;
  final Function(bool isCorrect) onOverrideAnswer;

  const ExerciseContentWidget({
    super.key,
    required this.card,
    required this.exerciseType,
    this.multipleChoiceOptions,
    required this.answerState,
    this.currentAnswerCorrect,
    required this.onCheckAnswer,
    required this.onOverrideAnswer,
  });

  @override
  State<ExerciseContentWidget> createState() => _ExerciseContentWidgetState();
}

class _ExerciseContentWidgetState extends State<ExerciseContentWidget> {
  String? _selectedAnswer;
  String? _selectedGender;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Listen to text changes to update button state
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Trigger rebuild to update button enabled state
    setState(() {});
  }

  @override
  void didUpdateWidget(ExerciseContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset state when card changes
    if (oldWidget.card.id != widget.card.id ||
        oldWidget.exerciseType != widget.exerciseType) {
      setState(() {
        _selectedAnswer = null;
        _selectedGender = null;
        _textController.clear();
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question/prompt section
          _buildPromptSection(context),

          const SizedBox(height: 24),

          // Answer section based on exercise type
          _buildAnswerSection(context),

          const SizedBox(height: 24),

          // Action button (Check Answer or Override buttons)
          _buildActionSection(context),
        ],
      ),
    );
  }

  Widget _buildPromptSection(BuildContext context) {
    final card = widget.card;

    // New exercise types handle their own prompts
    if (widget.exerciseType == ExerciseType.sentenceBuilding ||
        widget.exerciseType == ExerciseType.conjugationPractice ||
        widget.exerciseType == ExerciseType.articleSelection) {
      return const SizedBox.shrink();
    }

    // Listening comprehension hides the word — only the speaker button is shown
    if (widget.exerciseType == ExerciseType.listening) {
      return Column(
        children: [
          Text(
            _getInstructionText(),
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SpeakerButton(
            key: ValueKey('speaker_${card.id}_${widget.exerciseType}'),
            text: card.frontText,
            languageCode: card.language,
            size: 56,
            autoPlay: true,
          ),
        ],
      );
    }

    // Determine what to show based on exercise type
    final isReverse = widget.exerciseType == ExerciseType.reverseTranslation;
    final promptText = isReverse ? card.backText : card.frontText;
    final promptLanguage = isReverse ? 'en' : card.language;

    return Column(
      children: [
        // Instruction text
        Text(
          _getInstructionText(),
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Main prompt with speaker button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                promptText,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            SpeakerButton(
              text: promptText,
              languageCode: promptLanguage,
              size: 28,
              autoPlay:
                  !isReverse, // Only auto-play for foreign language prompts
            ),
          ],
        ),

        // German article if applicable
        if (card.germanArticle != null && !isReverse) ...[
          const SizedBox(height: 8),
          Text(
            card.germanArticle!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  String _getInstructionText() {
    switch (widget.exerciseType) {
      case ExerciseType.readingRecognition:
        return 'What does this word mean?';
      case ExerciseType.writingTranslation:
        return 'Type the translation:';
      case ExerciseType.multipleChoiceText:
        return 'Select the correct translation:';
      case ExerciseType.multipleChoiceIcon:
        return 'Select the matching icon:';
      case ExerciseType.reverseTranslation:
        return 'Translate to the target language:';
      case ExerciseType.listening:
        return 'Listen and recall the meaning:';
      case ExerciseType.speakingPronunciation:
        return 'Speak the word:';
      case ExerciseType.sentenceFill:
        return 'Fill in the blank:';
      case ExerciseType.sentenceBuilding:
        return 'Arrange the words:';
      case ExerciseType.conjugationPractice:
        return 'Provide the correct form:';
      case ExerciseType.articleSelection:
        return 'Choose the correct article:';
    }
  }

  Widget _buildAnswerSection(BuildContext context) {
    switch (widget.exerciseType) {
      case ExerciseType.multipleChoiceText:
      case ExerciseType.multipleChoiceIcon:
        return _buildMultipleChoiceSection(context);
      case ExerciseType.writingTranslation:
      case ExerciseType.reverseTranslation:
        return _buildWritingSection(context);
      case ExerciseType.sentenceBuilding:
        return SentenceBuildingExercise(
          card: widget.card,
          answerState: widget.answerState,
          currentAnswerCorrect: widget.currentAnswerCorrect,
          onCheckAnswer: widget.onCheckAnswer,
        );
      case ExerciseType.conjugationPractice:
        return ConjugationPracticeExercise(
          card: widget.card,
          answerState: widget.answerState,
          currentAnswerCorrect: widget.currentAnswerCorrect,
          onCheckAnswer: widget.onCheckAnswer,
        );
      case ExerciseType.articleSelection:
        return ArticleSelectionExercise(
          card: widget.card,
          answerState: widget.answerState,
          currentAnswerCorrect: widget.currentAnswerCorrect,
          onCheckAnswer: widget.onCheckAnswer,
        );
      case ExerciseType.listening:
        return _buildListeningSection(context);
      case ExerciseType.readingRecognition:
      default:
        return _buildReadingSection(context);
    }
  }

  Widget _buildMultipleChoiceSection(BuildContext context) {
    final options = widget.multipleChoiceOptions ?? [];
    final correctAnswer = widget.card.backText;
    final hasAnswered = widget.answerState == AnswerState.answered;

    return Column(
      children: options.map((option) {
        final isSelected = _selectedAnswer == option;
        final isCorrect = option == correctAnswer;

        Color? backgroundColor;
        Color? borderColor;
        IconData? icon;

        if (hasAnswered) {
          if (isCorrect) {
            backgroundColor = Colors.green.withValues(alpha: 0.1);
            borderColor = Colors.green;
            icon = Icons.check_circle;
          } else if (isSelected && !isCorrect) {
            backgroundColor = Colors.red.withValues(alpha: 0.1);
            borderColor = Colors.red;
            icon = Icons.cancel;
          }
        } else if (isSelected) {
          backgroundColor = Theme.of(
            context,
          ).primaryColor.withValues(alpha: 0.1);
          borderColor = Theme.of(context).primaryColor;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: hasAnswered
                ? null
                : () => _selectAndCheckAnswer(option, correctAnswer),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
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
                    Icon(icon, color: borderColor),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWritingSection(BuildContext context) {
    final hasAnswered = widget.answerState == AnswerState.answered;
    final correctAnswer = widget.exerciseType == ExerciseType.reverseTranslation
        ? widget.card.frontText
        : widget.card.backText;

    // Check if this is a noun to show gender selector
    final isNoun = widget.card.wordData is NounData;
    final nounData = isNoun ? widget.card.wordData as NounData : null;

    return Column(
      children: [
        // Gender selector for nouns (only when translating to German)
        if (isNoun &&
            widget.exerciseType == ExerciseType.reverseTranslation) ...[
          _buildGenderSelector(context, hasAnswered, nounData?.gender),
          const SizedBox(height: 12),
        ],

        TextField(
          controller: _textController,
          focusNode: _textFocusNode,
          enabled: !hasAnswered,
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: hasAnswered
                ? (widget.currentAnswerCorrect == true
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1))
                : null,
          ),
          style: const TextStyle(fontSize: 18),
          onChanged: (value) {},
          onSubmitted: hasAnswered ? null : (_) => _checkWritingAnswer(),
        ),

        if (hasAnswered) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Correct answer:',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                      Text(
                        correctAnswer,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReadingSection(BuildContext context) {
    final hasAnswered = widget.answerState == AnswerState.answered;
    final answer = widget.card.backText;

    if (!hasAnswered) {
      return InkWell(
        onTap: _onCheckAnswer,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Column(
            children: [
              Icon(Icons.visibility_off, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Tap to reveal the answer',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        children: [
          const Icon(Icons.lightbulb, size: 48, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            answer,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListeningSection(BuildContext context) {
    final hasAnswered = widget.answerState == AnswerState.answered;
    final card = widget.card;

    if (!hasAnswered) {
      return InkWell(
        onTap: _onCheckAnswer,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Column(
            children: [
              Icon(Icons.visibility_off, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Tap to reveal the answer',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        children: [
          const Icon(Icons.lightbulb, size: 48, color: Colors.amber),
          const SizedBox(height: 16),
          // Primary: the meaning (what the user was trying to recall)
          Text(
            card.backText,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          // Secondary: the word they heard, with speaker button for replay
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  card.frontText,
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              SpeakerButton(
                text: card.frontText,
                languageCode: card.language,
                size: 20,
              ),
            ],
          ),
          if (card.germanArticle != null) ...[
            const SizedBox(height: 4),
            Text(
              card.germanArticle!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    final hasAnswered = widget.answerState == AnswerState.answered;

    // New exercise types handle their own action buttons
    if (widget.exerciseType == ExerciseType.sentenceBuilding ||
        widget.exerciseType == ExerciseType.conjugationPractice ||
        widget.exerciseType == ExerciseType.articleSelection) {
      return const SizedBox.shrink();
    }

    // For reading/listening comprehension, tap-to-reveal is on the answer card itself
    if (!hasAnswered &&
        (widget.exerciseType == ExerciseType.readingRecognition ||
            widget.exerciseType == ExerciseType.listening)) {
      return const SizedBox.shrink();
    }

    // For multiple choice, answer is checked on selection - no button needed
    if (!hasAnswered &&
        (widget.exerciseType == ExerciseType.multipleChoiceText ||
            widget.exerciseType == ExerciseType.multipleChoiceIcon)) {
      return const SizedBox.shrink();
    }

    if (!hasAnswered) {
      return _buildCheckAnswerButton(context);
    }

    return _buildOverrideButtons(context);
  }

  Widget _buildCheckAnswerButton(BuildContext context) {
    final canCheck = _canCheckAnswer();

    String buttonText;
    IconData buttonIcon;

    switch (widget.exerciseType) {
      case ExerciseType.readingRecognition:
        buttonText = 'Reveal Answer';
        buttonIcon = Icons.visibility;
        break;
      default:
        buttonText = 'Check Answer';
        buttonIcon = Icons.check;
    }

    return ElevatedButton.icon(
      onPressed: canCheck ? _onCheckAnswer : null,
      icon: Icon(buttonIcon),
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool _canCheckAnswer() {
    switch (widget.exerciseType) {
      case ExerciseType.multipleChoiceText:
      case ExerciseType.multipleChoiceIcon:
        return _selectedAnswer != null;
      case ExerciseType.writingTranslation:
      case ExerciseType.reverseTranslation:
        return _textController.text.trim().isNotEmpty;
      case ExerciseType.readingRecognition:
      default:
        return true;
    }
  }

  void _onCheckAnswer() {
    bool isCorrect;

    switch (widget.exerciseType) {
      case ExerciseType.multipleChoiceText:
      case ExerciseType.multipleChoiceIcon:
        isCorrect = _selectedAnswer == widget.card.backText;
        break;
      case ExerciseType.writingTranslation:
        isCorrect = _checkWritingAnswer();
        break;
      case ExerciseType.reverseTranslation:
        isCorrect = _checkReverseAnswer();
        break;
      case ExerciseType.readingRecognition:
      case ExerciseType.listening:
      default:
        // For reading/listening, we just reveal - user decides if correct
        isCorrect = true; // Default to correct, user can override
    }

    widget.onCheckAnswer(isCorrect);
  }

  bool _checkWritingAnswer() {
    final userAnswer = _textController.text.trim().toLowerCase();
    final correctAnswer = widget.card.backText.trim().toLowerCase();
    return userAnswer == correctAnswer;
  }

  bool _checkReverseAnswer() {
    final userAnswer = _textController.text.trim().toLowerCase();
    var correctAnswer = widget.card.frontText.trim().toLowerCase();

    // For nouns, strip the article from correct answer since user selects it separately
    if (widget.card.wordData is NounData) {
      final nounData = widget.card.wordData as NounData;

      // Remove article prefix (der/die/das) from correct answer
      correctAnswer = correctAnswer.replaceFirst(
        RegExp(r'^(der|die|das)\s+'),
        '',
      );

      final genderCorrect = _selectedGender == nounData.gender;
      final textCorrect = userAnswer == correctAnswer;

      return textCorrect && genderCorrect;
    }

    return userAnswer == correctAnswer;
  }

  /// For multiple choice: select answer and immediately check it
  void _selectAndCheckAnswer(String option, String correctAnswer) {
    setState(() => _selectedAnswer = option);
    final isCorrect = option == correctAnswer;
    widget.onCheckAnswer(isCorrect);
  }

  Widget _buildGenderSelector(
    BuildContext context,
    bool hasAnswered,
    String? correctGender,
  ) {
    const genders = ['der', 'die', 'das'];

    return Row(
      children: genders.map((gender) {
        final isSelected = _selectedGender == gender;
        final isCorrect = gender == correctGender;

        Color? backgroundColor;
        Color? borderColor;

        if (hasAnswered) {
          if (isCorrect) {
            backgroundColor = Colors.green.withValues(alpha: 0.1);
            borderColor = Colors.green;
          } else if (isSelected && !isCorrect) {
            backgroundColor = Colors.red.withValues(alpha: 0.1);
            borderColor = Colors.red;
          }
        } else if (isSelected) {
          backgroundColor = _getGenderColor(gender).withValues(alpha: 0.2);
          borderColor = _getGenderColor(gender);
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                gender,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: borderColor ?? Colors.grey[700],
                ),
              ),
              selected: isSelected,
              onSelected: hasAnswered
                  ? null
                  : (selected) {
                      setState(
                        () => _selectedGender = selected ? gender : null,
                      );
                    },
              selectedColor: backgroundColor,
              backgroundColor: Colors.grey[100],
              side: BorderSide(
                color: borderColor ?? Colors.grey[300]!,
                width: 2,
              ),
              showCheckmark: hasAnswered && isCorrect,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getGenderColor(String gender) {
    return switch (gender) {
      'der' => Colors.blue,
      'die' => Colors.pink,
      'das' => Colors.green,
      _ => Colors.grey,
    };
  }

  Widget _buildOverrideButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.onOverrideAnswer(false),
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
                onPressed: () => widget.onOverrideAnswer(true),
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
        const SizedBox(height: 12),
        Text(
          widget.currentAnswerCorrect == true
              ? 'Auto-validated as correct • Swipe to continue'
              : 'Auto-validated as incorrect • Swipe to continue',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
