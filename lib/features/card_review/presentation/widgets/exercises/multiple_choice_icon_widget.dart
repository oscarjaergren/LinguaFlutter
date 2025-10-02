import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../shared/shared.dart';
import '../../../domain/providers/exercise_session_provider.dart';
import '../exercise_stats_widget.dart';

/// Multiple Choice (Icon) Exercise: Select the correct icon for the word
class MultipleChoiceIconWidget extends StatefulWidget {
  const MultipleChoiceIconWidget({super.key});

  @override
  State<MultipleChoiceIconWidget> createState() => _MultipleChoiceIconWidgetState();
}

class _MultipleChoiceIconWidgetState extends State<MultipleChoiceIconWidget> {
  IconModel? _selectedIcon;
  bool _hasSubmitted = false;
  List<IconModel> _iconOptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateIconOptions();
    });
  }

  void _generateIconOptions() {
    final provider = Provider.of<ExerciseSessionProvider>(context, listen: false);
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final currentCard = provider.currentCard;
    
    if (currentCard?.icon == null) return;

    // Get other cards with icons
    final otherIcons = cardProvider.allCards
        .where((c) => c.icon != null && c.id != currentCard!.id)
        .map((c) => c.icon!)
        .toSet()
        .toList()
      ..shuffle();

    // Create options: correct + 3 wrong
    final options = [
      currentCard!.icon!,
      ...otherIcons.take(3),
    ]..shuffle();

    setState(() {
      _iconOptions = options;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseSessionProvider>(
      builder: (context, provider, child) {
        final card = provider.currentCard;
        
        if (card == null || card.icon == null || _iconOptions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final correctIcon = card.icon!;
        final isCorrect = _selectedIcon?.name == correctIcon.name;

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
                      'Select the correct icon:',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Front text with speaker button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            card.frontText,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SpeakerButton(
                          text: card.frontText,
                          languageCode: card.language,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.backText,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (card.germanArticle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.germanArticle!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Icon options in a grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: _iconOptions.map((iconOption) {
                        final isSelected = _selectedIcon?.name == iconOption.name;
                        final isThisCorrect = iconOption.name == correctIcon.name;
                        
                        Color? backgroundColor;
                        Color? borderColor;
                        Widget? badge;
                        
                        if (_hasSubmitted) {
                          if (isThisCorrect) {
                            backgroundColor = Colors.green[50];
                            borderColor = Colors.green;
                            badge = const Icon(Icons.check_circle, color: Colors.green);
                          } else if (isSelected && !isCorrect) {
                            backgroundColor = Colors.red[50];
                            borderColor = Colors.red;
                            badge = const Icon(Icons.cancel, color: Colors.red);
                          }
                        } else if (isSelected) {
                          backgroundColor = Theme.of(context).primaryColor.withValues(alpha: 0.1);
                          borderColor = Theme.of(context).primaryColor;
                        }

                        return InkWell(
                          onTap: _hasSubmitted
                              ? null
                              : () => setState(() => _selectedIcon = iconOption),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: backgroundColor ?? Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: borderColor ?? Colors.grey[300]!,
                                width: 3,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: IconifyIcon(
                                    icon: iconOption,
                                    size: 80,
                                    color: borderColor ?? Colors.grey[700],
                                  ),
                                ),
                                if (badge != null)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: badge,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
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
            Icons.image,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Multiple Choice (Icon)',
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
              onPressed: _selectedIcon != null
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
                            _selectedIcon = null;
                            _hasSubmitted = false;
                          });
                          _generateIconOptions();
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
                            _selectedIcon = null;
                            _hasSubmitted = false;
                          });
                          _generateIconOptions();
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
