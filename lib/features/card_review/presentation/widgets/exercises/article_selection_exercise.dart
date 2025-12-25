import 'package:flutter/material.dart';
import '../../../../../shared/domain/models/card_model.dart';
import '../../../domain/providers/practice_session_provider.dart';

/// Exercise widget for article selection - choose correct German article
class ArticleSelectionExercise extends StatefulWidget {
  final CardModel card;
  final AnswerState answerState;
  final bool? currentAnswerCorrect;
  final ValueChanged<bool> onCheckAnswer;

  const ArticleSelectionExercise({
    super.key,
    required this.card,
    required this.answerState,
    required this.currentAnswerCorrect,
    required this.onCheckAnswer,
  });

  @override
  State<ArticleSelectionExercise> createState() => _ArticleSelectionExerciseState();
}

class _ArticleSelectionExerciseState extends State<ArticleSelectionExercise> {
  String? _selectedArticle;
  
  static const List<String> _articles = ['der', 'die', 'das'];
  
  String? get _correctArticle {
    // Try to extract from germanArticle field
    if (widget.card.germanArticle != null) {
      return widget.card.germanArticle!.toLowerCase();
    }
    
    // Try to extract from front text (e.g., "der Hund" -> "der")
    final frontText = widget.card.frontText.toLowerCase().trim();
    for (final article in _articles) {
      if (frontText.startsWith('$article ')) {
        return article;
      }
    }
    
    return null;
  }
  
  String get _nounWithoutArticle {
    final frontText = widget.card.frontText.trim();
    
    // Remove article if present
    for (final article in ['der', 'die', 'das', 'Der', 'Die', 'Das']) {
      if (frontText.startsWith('$article ')) {
        return frontText.substring(article.length + 1);
      }
    }
    
    return frontText;
  }

  void _selectArticle(String article) {
    if (widget.answerState == AnswerState.answered) return;
    
    setState(() {
      _selectedArticle = article;
    });
  }

  void _checkAnswer() {
    if (_selectedArticle == null) return;
    
    final isCorrect = _selectedArticle!.toLowerCase() == _correctArticle?.toLowerCase();
    widget.onCheckAnswer(isCorrect);
  }

  Color _getArticleColor(String article) {
    switch (article) {
      case 'der':
        return Colors.blue;
      case 'die':
        return Colors.red;
      case 'das':
        return Colors.green;
      default:
        return Colors.grey;
    }
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
          'Choose the correct article:',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        // Noun display
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '___',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _nounWithoutArticle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
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
        
        // Article options
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _articles.map((article) {
            final isSelected = _selectedArticle == article;
            final articleColor = _getArticleColor(article);
            final isCorrectAnswer = article == _correctArticle;
            
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
              } else if (isCorrectAnswer) {
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
                    onTap: !isAnswered ? () => _selectArticle(article) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: borderColor ?? 
                                 (isSelected 
                                     ? articleColor 
                                     : colorScheme.outline.withValues(alpha: 0.3)),
                          width: isSelected || (isAnswered && isCorrectAnswer) ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            article,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: textColor ?? 
                                     (isSelected ? articleColor : colorScheme.onSurface),
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
        ),
        
        const SizedBox(height: 24),
        
        // Check answer button
        if (!isAnswered)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedArticle != null ? _checkAnswer : null,
              child: const Text('Check Answer'),
            ),
          ),
        
        // Gender hint
        if (isAnswered) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline, 
                  size: 16, 
                  color: colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  _getGenderHint(_correctArticle ?? ''),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  String _getGenderHint(String article) {
    switch (article.toLowerCase()) {
      case 'der':
        return 'Masculine (der) - blue';
      case 'die':
        return 'Feminine (die) - red';
      case 'das':
        return 'Neuter (das) - green';
      default:
        return '';
    }
  }
}
