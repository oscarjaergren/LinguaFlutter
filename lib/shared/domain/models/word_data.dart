import 'package:freezed_annotation/freezed_annotation.dart';

part 'word_data.freezed.dart';
part 'word_data.g.dart';

/// Word type classification
enum WordType {
  verb,
  noun,
  adjective,
  adverb,
  phrase,
  other,
}

/// Tagged union for word-specific grammatical data.
/// 
/// Each word type has its own data structure with relevant fields
/// for that part of speech. This enables type-safe handling of
/// different word types with exhaustive pattern matching.
@freezed
sealed class WordData with _$WordData {
  /// Data for verbs including conjugation forms
  const factory WordData.verb({
    /// Whether this is a regular verb (conjugations can be computed)
    @Default(true) bool isRegular,
    
    /// Whether this is a separable verb (e.g., aufmachen → ich mache auf)
    @Default(false) bool isSeparable,
    
    /// The separable prefix if applicable (e.g., "auf" for aufmachen)
    String? separablePrefix,
    
    /// Auxiliary verb for Perfekt: "haben" or "sein"
    @Default('haben') String auxiliary,
    
    /// 2nd person singular present (du form) - only if irregular
    /// e.g., "sprichst" for sprechen (stem change e→i)
    String? presentDu,
    
    /// 3rd person singular present (er/sie/es form) - only if irregular
    /// e.g., "spricht" for sprechen
    String? presentEr,
    
    /// Simple past stem (Präteritum)
    /// e.g., "sprach" for sprechen
    String? pastSimple,
    
    /// Past participle (Partizip II)
    /// e.g., "gesprochen" for sprechen
    String? pastParticiple,
  }) = VerbData;

  /// Data for nouns including gender and declension
  const factory WordData.noun({
    /// Grammatical gender: "der", "die", or "das"
    required String gender,
    
    /// Plural form
    /// e.g., "Bücher" for "Buch"
    String? plural,
    
    /// Genitive singular form (for strong nouns)
    /// e.g., "des Buches" for "das Buch"
    String? genitive,
  }) = NounData;

  /// Data for adjectives including comparison forms
  const factory WordData.adjective({
    /// Comparative form
    /// e.g., "größer" for "groß"
    String? comparative,
    
    /// Superlative form
    /// e.g., "größten" for "groß"
    String? superlative,
  }) = AdjectiveData;

  /// Data for adverbs
  const factory WordData.adverb({
    /// Any special notes about usage
    String? usageNote,
  }) = AdverbData;

  /// JSON serialization
  factory WordData.fromJson(Map<String, dynamic> json) => _$WordDataFromJson(json);
}
