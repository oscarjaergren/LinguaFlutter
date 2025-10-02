import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/shared.dart';
import '../../domain/providers/exercise_session_provider.dart';
import '../widgets/exercises/reading_recognition_widget.dart';
import '../widgets/exercises/writing_translation_widget.dart';
import '../widgets/exercises/multiple_choice_text_widget.dart';
import '../widgets/exercises/multiple_choice_icon_widget.dart';
import '../widgets/exercises/reverse_translation_widget.dart';
import '../widgets/exercise_completion_screen.dart';

/// Main screen for exercise practice sessions
class ExerciseSessionScreen extends StatefulWidget {
  const ExerciseSessionScreen({super.key});

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
    });
  }

  void _startSession() {
    final provider = Provider.of<ExerciseSessionProvider>(context, listen: false);
    if (!provider.isSessionActive) {
      provider.startSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseSessionProvider>(
      builder: (context, provider, child) {
        if (!provider.isSessionActive) {
          return ExerciseCompletionScreen(
            correctCount: provider.correctCount,
            incorrectCount: provider.incorrectCount,
            onRestart: () => provider.restartSession(),
            onClose: () => Navigator.of(context).pop(),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Practice'),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '${provider.currentIndex + 1}/${provider.totalCount}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4.0),
              child: LinearProgressIndicator(
                value: provider.progress,
                backgroundColor: Colors.grey[300],
              ),
            ),
          ),
          body: SafeArea(
            child: _buildExerciseWidget(provider),
          ),
        );
      },
    );
  }

  Widget _buildExerciseWidget(ExerciseSessionProvider provider) {
    final exerciseType = provider.currentExerciseType;
    
    if (exerciseType == null || provider.currentCard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _getExerciseWidgetForType(exerciseType),
    );
  }

  Widget _getExerciseWidgetForType(ExerciseType type) {
    switch (type) {
      case ExerciseType.readingRecognition:
        return const ReadingRecognitionWidget(key: ValueKey('reading'));
      case ExerciseType.writingTranslation:
        return const WritingTranslationWidget(key: ValueKey('writing'));
      case ExerciseType.multipleChoiceText:
        return const MultipleChoiceTextWidget(key: ValueKey('mc_text'));
      case ExerciseType.multipleChoiceIcon:
        return const MultipleChoiceIconWidget(key: ValueKey('mc_icon'));
      case ExerciseType.reverseTranslation:
        return const ReverseTranslationWidget(key: ValueKey('reverse'));
      default:
        return Center(
          child: Text('Exercise type ${type.displayName} not implemented yet'),
        );
    }
  }
}
