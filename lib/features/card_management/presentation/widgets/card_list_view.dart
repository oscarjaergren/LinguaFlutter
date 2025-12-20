import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/navigation/app_router.dart';
import '../../../duplicate_detection/duplicate_detection.dart';
import '../../domain/providers/card_management_provider.dart';
import '../view_models/card_list_view_model.dart';
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
    // Watch CardManagementProvider directly to ensure rebuild on changes
    final cardProvider = context.watch<CardManagementProvider>();
    
    return Consumer<CardListViewModel>(
      builder: (context, vm, child) {
        // Use cardProvider.filteredCards to get fresh data
        final cards = cardProvider.filteredCards;
        if (cardProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (vm.errorMessage != null) {
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
                  'Error: ${vm.errorMessage}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => vm.refreshCards(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Search bar
            if (vm.isSearching)
              SearchBarWidget(
                onSearchChanged: vm.updateSearchQuery,
                onSearchClosed: vm.stopSearch,
                initialQuery: vm.searchQuery,
              ),

            // Filter chips
            if (vm.selectedCategory.isNotEmpty ||
                vm.selectedTags.isNotEmpty ||
                vm.showOnlyDue ||
                vm.showOnlyFavorites ||
                vm.showOnlyDuplicates)
              _buildFilterChips(context, vm),

            // Cards count and stats
            _buildStatsRow(context, vm),

            // Card list - use cards from cardProvider for fresh data
            Expanded(
              child: cards.isEmpty
                  ? _buildEmptyState(context, vm)
                  : _buildCardListDirect(context, vm, cards),
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
          if (viewModel.showOnlyDuplicates)
            Chip(
              label: Text('Duplicates (${viewModel.duplicateCount})'),
              onDeleted: viewModel.toggleShowOnlyDuplicates,
              deleteIcon: const Icon(Icons.close, size: 18),
              backgroundColor: Colors.orange.withValues(alpha: 0.2),
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
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No cards match your filters' : 'No cards yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting your search or filters'
                : 'Create your first card to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
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

  Widget _buildCardListDirect(BuildContext context, CardListViewModel viewModel, List<CardModel> cards) {
    return ListView.builder(
      key: ValueKey(cards.length), // Force rebuild when card count changes
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final duplicates = viewModel.getDuplicatesForCard(card.id);
        return CardItemWidget(
          key: ValueKey(card.id), // Unique key per card
          card: card,
          onTap: () => _onCardTap(context, card),
          onEdit: () => _onCardEdit(context, card),
          onDelete: () => _onCardDelete(context, viewModel, card),
          onToggleFavorite: () => viewModel.toggleCardFavorite(card.id),
          duplicates: duplicates.isNotEmpty ? duplicates : null,
          onDuplicateTap: duplicates.isNotEmpty 
              ? () => _showDuplicatesDialog(context, card, duplicates, viewModel)
              : null,
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
    // Navigate to edit screen using go_router
    context.pushCardEdit(card.id);
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
  
  void _showDuplicatesDialog(
    BuildContext context, 
    CardModel card, 
    List<DuplicateMatch> duplicates,
    CardListViewModel viewModel,
  ) {
    DuplicatesDialog.show(
      context,
      card: card,
      duplicates: duplicates,
      onDeleteCard: (cardToDelete) => _onCardDelete(context, viewModel, cardToDelete),
    );
  }
}
