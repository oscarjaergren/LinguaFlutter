import 'package:json_annotation/json_annotation.dart';

/// Types of exercises available for flashcard practice
/// Each exercise type tests different language skills
enum ExerciseType {
  /// Read the front text and recall the back text (with optional icon)
  /// Tests: Recognition, visual memory
  @JsonValue('reading_recognition')
  readingRecognition,
  
  /// Type the correct translation of the word
  /// Tests: Spelling, active recall, writing
  @JsonValue('writing_translation')
  writingTranslation,
  
  /// Select the correct translation from multiple text options
  /// Tests: Recognition, comprehension
  @JsonValue('multiple_choice_text')
  multipleChoiceText,
  
  /// Select the correct icon that represents the word
  /// Tests: Visual association, meaning comprehension
  @JsonValue('multiple_choice_icon')
  multipleChoiceIcon,
  
  /// Translate from native language to target language (reverse of normal)
  /// Tests: Active production, harder recall
  @JsonValue('reverse_translation')
  reverseTranslation,
  
  /// Listen to audio and identify the correct word (future feature)
  /// Tests: Listening comprehension, pronunciation recognition
  @JsonValue('listening_recognition')
  listeningRecognition,
  
  /// Speak the word and get pronunciation feedback (future feature)
  /// Tests: Speaking, pronunciation
  @JsonValue('speaking_pronunciation')
  speakingPronunciation,
  
  /// Fill in the blank in a sentence with the correct word (future feature)
  /// Tests: Context usage, grammar
  @JsonValue('sentence_fill')
  sentenceFill,
}

/// Extension methods for ExerciseType
extension ExerciseTypeExtension on ExerciseType {
  /// Human-readable display name for the exercise type
  String get displayName {
    switch (this) {
      case ExerciseType.readingRecognition:
        return 'Reading Recognition';
      case ExerciseType.writingTranslation:
        return 'Writing Translation';
      case ExerciseType.multipleChoiceText:
        return 'Multiple Choice (Text)';
      case ExerciseType.multipleChoiceIcon:
        return 'Multiple Choice (Icon)';
      case ExerciseType.reverseTranslation:
        return 'Reverse Translation';
      case ExerciseType.listeningRecognition:
        return 'Listening Recognition';
      case ExerciseType.speakingPronunciation:
        return 'Speaking Pronunciation';
      case ExerciseType.sentenceFill:
        return 'Sentence Fill';
    }
  }
  
  /// Description of what this exercise type tests
  String get description {
    switch (this) {
      case ExerciseType.readingRecognition:
        return 'See the word and recall its meaning';
      case ExerciseType.writingTranslation:
        return 'Type the correct translation';
      case ExerciseType.multipleChoiceText:
        return 'Choose the correct meaning from options';
      case ExerciseType.multipleChoiceIcon:
        return 'Choose the matching icon';
      case ExerciseType.reverseTranslation:
        return 'Translate from your native language';
      case ExerciseType.listeningRecognition:
        return 'Listen and identify the word';
      case ExerciseType.speakingPronunciation:
        return 'Speak the word correctly';
      case ExerciseType.sentenceFill:
        return 'Complete the sentence with the word';
    }
  }
  
  /// Whether this exercise type is currently implemented
  bool get isImplemented {
    switch (this) {
      case ExerciseType.readingRecognition:
      case ExerciseType.writingTranslation:
      case ExerciseType.multipleChoiceText:
      case ExerciseType.multipleChoiceIcon:
      case ExerciseType.reverseTranslation:
        return true;
      case ExerciseType.listeningRecognition:
      case ExerciseType.speakingPronunciation:
      case ExerciseType.sentenceFill:
        return false;
    }
  }
  
  /// Whether this exercise type requires an icon to function
  bool get requiresIcon {
    return this == ExerciseType.multipleChoiceIcon;
  }
  
  /// Whether this exercise type benefits from having an icon
  bool get benefitsFromIcon {
    return this == ExerciseType.readingRecognition;
  }
  
  /// Icon name to represent this exercise type in UI
  String get iconName {
    switch (this) {
      case ExerciseType.readingRecognition:
        return 'mdi:book-open-page-variant';
      case ExerciseType.writingTranslation:
        return 'mdi:pencil';
      case ExerciseType.multipleChoiceText:
        return 'mdi:format-list-checks';
      case ExerciseType.multipleChoiceIcon:
        return 'mdi:image-multiple';
      case ExerciseType.reverseTranslation:
        return 'mdi:swap-horizontal';
      case ExerciseType.listeningRecognition:
        return 'mdi:ear-hearing';
      case ExerciseType.speakingPronunciation:
        return 'mdi:microphone';
      case ExerciseType.sentenceFill:
        return 'mdi:text-box';
    }
  }
}
