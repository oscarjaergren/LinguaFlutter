import '../../../../shared/domain/models/word_data.dart';

/// Result from AI word enrichment containing all grammar data
class WordEnrichmentResult {
  final WordType wordType;
  final String? translation;
  final WordData? wordData;
  final List<String> examples;
  final String? notes;

  const WordEnrichmentResult({
    required this.wordType,
    this.translation,
    this.wordData,
    this.examples = const [],
    this.notes,
  });

  factory WordEnrichmentResult.fromJson(Map<String, dynamic> json) {
    final typeStr = json['wordType'] as String? ?? 'other';
    final wordType = WordType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => WordType.other,
    );

    WordData? wordData;
    if (json['grammar'] != null) {
      final grammar = json['grammar'] as Map<String, dynamic>;
      wordData = switch (wordType) {
        WordType.verb => WordData.verb(
          isRegular: grammar['isRegular'] as bool? ?? true,
          isSeparable: grammar['isSeparable'] as bool? ?? false,
          separablePrefix: grammar['separablePrefix'] as String?,
          auxiliary: grammar['auxiliary'] as String? ?? 'haben',
          presentSecondPerson: grammar['presentSecondPerson'] as String?,
          presentThirdPerson: grammar['presentThirdPerson'] as String?,
          pastSimple: grammar['pastSimple'] as String?,
          pastParticiple: grammar['pastParticiple'] as String?,
        ),
        WordType.noun => WordData.noun(
          gender: grammar['gender'] as String? ?? 'das',
          plural: grammar['plural'] as String?,
          genitive: grammar['genitive'] as String?,
        ),
        WordType.adjective => WordData.adjective(
          comparative: grammar['comparative'] as String?,
          superlative: grammar['superlative'] as String?,
        ),
        WordType.adverb => WordData.adverb(
          usageNote: grammar['usageNote'] as String?,
        ),
        _ => null,
      };
    }

    return WordEnrichmentResult(
      wordType: wordType,
      translation: json['translation'] as String?,
      wordData: wordData,
      examples:
          (json['examples'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      notes: json['notes'] as String?,
    );
  }
}
