import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/card_management_notifier.dart';
import 'card_list_state.dart';
import '../../../../shared/services/logger_service.dart';

final cardListNotifierProvider =
    NotifierProvider<CardListNotifier, CardListState>(() => CardListNotifier());

class CardListNotifier extends Notifier<CardListState> {
  @override
  CardListState build() {
    return const CardListState();
  }

  void toggleSearch() {
    final newSearchState = !state.isSearching;
    state = state.copyWith(isSearching: newSearchState);
    if (!newSearchState) {
      clearSearch();
    }
  }

  void updateSearchQuery(String query) {
    ref.read(cardManagementNotifierProvider.notifier).searchCards(query);
  }

  void clearSearch() {
    ref.read(cardManagementNotifierProvider.notifier).searchCards('');
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await ref
          .read(cardManagementNotifierProvider.notifier)
          .deleteCard(cardId);
    } catch (e) {
      // Error is handled by the underlying notifier, log for debugging
      LoggerService.debug('Error deleting card', e);
    }
  }

  Future<void> toggleFavorite(String cardId) async {
    try {
      await ref
          .read(cardManagementNotifierProvider.notifier)
          .toggleFavorite(cardId);
    } catch (e) {
      // Error is handled by the underlying notifier, log for debugging
      LoggerService.debug('Error toggling favorite', e);
    }
  }
}
