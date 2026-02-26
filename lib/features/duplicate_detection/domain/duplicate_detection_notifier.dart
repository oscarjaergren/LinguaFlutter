import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../data/services/duplicate_detection_service.dart';
import 'models/duplicate_match.dart';
import 'duplicate_detection_state.dart';

final duplicateDetectionNotifierProvider =
    NotifierProvider<DuplicateDetectionNotifier, DuplicateDetectionState>(
      () => DuplicateDetectionNotifier(),
    );

class DuplicateDetectionNotifier extends Notifier<DuplicateDetectionState> {
  late final DuplicateDetectionService _service;

  /// Optional factory for testing.
  static DuplicateDetectionService Function()? serviceFactory;

  @override
  DuplicateDetectionState build() {
    _service = serviceFactory != null
        ? serviceFactory!()
        : DuplicateDetectionService();
    return const DuplicateDetectionState();
  }

  void analyzeCards(List<CardModel> cards) {
    state = state.copyWith(isAnalyzing: true);
    try {
      final map = _service.findAllDuplicates(cards);
      state = state.copyWith(duplicateMap: map, isAnalyzing: false);
    } catch (_) {
      state = state.copyWith(isAnalyzing: false);
    }
  }

  void analyzeCardsForLanguage(List<CardModel> allCards, String language) {
    final cardsToCheck = language.isEmpty
        ? allCards
        : allCards.where((c) => c.language == language).toList();
    analyzeCards(cardsToCheck);
  }

  void clear() {
    state = const DuplicateDetectionState();
  }
}
