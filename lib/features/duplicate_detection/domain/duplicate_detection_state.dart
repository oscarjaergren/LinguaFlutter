import 'models/duplicate_match.dart';

/// Immutable state for duplicate detection
class DuplicateDetectionState {
  final Map<String, List<DuplicateMatch>> duplicateMap;
  final bool isAnalyzing;

  const DuplicateDetectionState({
    this.duplicateMap = const {},
    this.isAnalyzing = false,
  });

  int get duplicateCount => duplicateMap.length;

  Set<String> get cardIdsWithDuplicates => duplicateMap.keys.toSet();

  DuplicateDetectionState copyWith({
    Map<String, List<DuplicateMatch>>? duplicateMap,
    bool? isAnalyzing,
  }) {
    return DuplicateDetectionState(
      duplicateMap: duplicateMap ?? this.duplicateMap,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }
}
