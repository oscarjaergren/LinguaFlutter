import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/card_list_view_model.dart';
import '../../../../shared/domain/models/card_model.dart';
import 'card_item_widget.dart';
import 'search_bar_widget.dart';

/// Main view widget for displaying the card list
class CardListView extends StatelessWidget {
  final CardListViewModel viewModel;

  const CardListView({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CardListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (viewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${viewModel.errorMessage}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.refreshCards(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Search bar
            if (viewModel.isSearching)
              SearchBarWidget(
                onSearchChanged: viewModel.updateSearchQuery,
                onSearchClosed: viewModel.stopSearch,
                initialQuery: viewModel.searchQuery,
              ),

            // Filter chips
            if (viewModel.selectedCategory.isNotEmpty ||
                viewModel.selectedTags.isNotEmpty ||
                viewModel.showOnlyDue ||
                viewModel.showOnlyFavorites)
              _buildFilterChips(context, viewModel),

            // Cards count and stats
            _buildStatsRow(context, viewModel),

            // Card list
            Expanded(
              child: viewModel.displayCards.isEmpty
                  ? _buildEmptyState(context, viewModel)
                  : _buildCardList(context, viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips(BuildContext context, CardListViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (viewModel.selectedCategory.isNotEmpty)
            Chip(
              label: Text('Category: ${viewModel.selectedCategory}'),
              onDeleted: viewModel.clearCategoryFilter,
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
          if (viewModel.selectedTags.isNotEmpty)
            ...viewModel.selectedTags.map(
              (tag) => Chip(
                label: Text('Tag: $tag'),
                onDeleted: () => viewModel.toggleTag(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
              ),
            ),
          if (viewModel.showOnlyDue)
            Chip(
              label: const Text('Due for review'),
              onDeleted: viewModel.toggleShowOnlyDue,
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
          if (viewModel.showOnlyFavorites)
            Chip(
              label: const Text('Favorites'),
              onDeleted: viewModel.toggleShowOnlyFavorites,
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
          TextButton(
            onPressed: viewModel.clearAllFilters,
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, CardListViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            viewModel.getCardCountText(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            viewModel.getReviewStatusText(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: viewModel.canStartReview
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, CardListViewModel viewModel) {
    final hasFilters = viewModel.selectedCategory.isNotEmpty ||
        viewModel.selectedTags.isNotEmpty ||
        viewModel.showOnlyDue ||
        viewModel.showOnlyFavorites ||
        viewModel.searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_list_off : Icons.library_books_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No cards match your filters' : 'No cards yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting your search or filters'
                : 'Create your first card to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
          if (hasFilters) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: viewModel.clearAllFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardList(BuildContext context, CardListViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.displayCards.length,
      itemBuilder: (context, index) {
        final card = viewModel.displayCards[index];
        return CardItemWidget(
          card: card,
          onTap: () => _onCardTap(context, card),
          onEdit: () => _onCardEdit(context, card),
          onDelete: () => _onCardDelete(context, viewModel, card),
          onToggleFavorite: () => viewModel.toggleCardFavorite(card.id),
        );
      },
    );
  }

  void _onCardTap(BuildContext context, CardModel card) {
    // Navigate to card detail or start single card review
    // This will be updated when we implement navigation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(card.frontText),
        content: Text(card.backText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onCardEdit(BuildContext context, CardModel card) {
    // Navigate to edit screen
    // This will be updated when we implement navigation
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SimpleCardCreationScreen(cardToEdit: card),
      ),
    );
  }

  void _onCardDelete(BuildContext context, CardListViewModel viewModel, CardModel card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Are you sure you want to delete "${card.frontText}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              viewModel.deleteCard(card.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
