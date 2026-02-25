import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/navigation/app_router.dart';
import '../../../duplicate_detection/duplicate_detection.dart';
import '../../domain/providers/card_management_notifier.dart';
import '../../domain/providers/card_management_state.dart';
import '../view_models/card_list_notifier.dart';
import 'card_item_widget.dart';
import 'search_bar_widget.dart';

/// Main view widget for displaying the card list
class CardListView extends ConsumerWidget {
  const CardListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(cardListNotifierProvider);
    final listNotifier = ref.read(cardListNotifierProvider.notifier);
    final managementState = ref.watch(cardManagementNotifierProvider);
    final managementNotifier = ref.read(
      cardManagementNotifierProvider.notifier,
    );
    final duplicateState = ref.watch(duplicateDetectionNotifierProvider);

    final cards = managementState.filteredCards;

    if (managementState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (managementState.errorMessage != null) {
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
              'Error: ${managementState.errorMessage}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: managementNotifier.loadCards,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search bar
        if (listState.isSearching)
          SearchBarWidget(
            onSearchChanged: listNotifier.updateSearchQuery,
            onSearchClosed: listNotifier.toggleSearch,
            initialQuery: managementState.searchQuery,
          ),

        // Filter chips
        if (managementState.selectedTags.isNotEmpty ||
            managementState.showOnlyDue ||
            managementState.showOnlyFavorites ||
            managementState.showOnlyDuplicates)
          _buildFilterChips(context, managementState, managementNotifier),

        // Cards count and stats
        _buildStatsRow(context, managementState),

        // Card list
        Expanded(
          child: cards.isEmpty
              ? _buildEmptyState(context, managementState, managementNotifier)
              : _buildCardListDirect(context, cards, duplicateState),
        ),
      ],
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    CardManagementState state,
    CardManagementNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (state.selectedTags.isNotEmpty)
            ...state.selectedTags.map(
              (tag) => Chip(
                label: Text('Tag: $tag'),
                onDeleted: () => notifier.toggleTag(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
              ),
            ),
          if (state.showOnlyDue)
            Chip(
              label: const Text('Due for review'),
              onDeleted: notifier.toggleShowOnlyDue,
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
          if (state.showOnlyFavorites)
            Chip(
              label: const Text('Favorites'),
              onDeleted: notifier.toggleShowOnlyFavorites,
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
          if (state.showOnlyDuplicates)
            Chip(
              label: Consumer(
                builder: (context, ref, _) {
                  final duplicateCount = ref.watch(
                    duplicateDetectionNotifierProvider.select(
                      (s) => s.duplicateCount,
                    ),
                  );
                  return Text('Duplicates ($duplicateCount)');
                },
              ),
              onDeleted: notifier.toggleShowOnlyDuplicates,
              deleteIcon: const Icon(Icons.close, size: 18),
              backgroundColor: Colors.orange.withValues(alpha: 0.2),
            ),
          TextButton(
            onPressed: notifier.clearAllFilters,
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, CardManagementState state) {
    final count = state.filteredCards.length;
    final total = state.allCards.length;
    final countText = count == total
        ? 'Showing all $total cards'
        : 'Showing $count of $total cards';
    final reviewText = state.dueCount > 0
        ? 'Review ${state.dueCount} cards'
        : 'Nothing to review';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(countText, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            reviewText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: state.dueCount > 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    CardManagementState state,
    CardManagementNotifier notifier,
  ) {
    final hasFilters =
        state.selectedTags.isNotEmpty ||
        state.showOnlyDue ||
        state.showOnlyFavorites ||
        state.searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_list_off : Icons.library_books_outlined,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No cards match your filters' : 'No cards yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting your search or filters'
                : 'Create your first card to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
          if (hasFilters) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: notifier.clearAllFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardListDirect(
    BuildContext context,
    List<CardModel> cards,
    DuplicateDetectionState duplicateState,
  ) {
    return ListView.builder(
      key: ValueKey(cards.length),
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final duplicates = duplicateState.duplicateMap[card.id] ?? [];
        return _AnimatedCardItem(
          key: ValueKey(card.id),
          card: card,
          duplicates: duplicates,
          onTap: () => _onCardTap(context, card),
          onEdit: () => _onCardEdit(context, card),
          onDelete: (ref) => _onCardDelete(context, ref, card),
          onUndoDismiss: (ref) =>
              ref.read(cardManagementNotifierProvider.notifier).saveCard(card),
          onDuplicateTap: duplicates.isNotEmpty
              ? (ref) => _showDuplicatesDialog(context, card, duplicates, ref)
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

  void _onCardDelete(BuildContext context, WidgetRef ref, CardModel card) {
    final listNotifier = ref.read(cardListNotifierProvider.notifier);

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
              listNotifier.deleteCard(card.id);
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
    WidgetRef ref,
  ) {
    DuplicatesDialog.show(
      context,
      card: card,
      duplicates: duplicates,
      onDeleteCard: (cardToDelete) => _onCardDelete(context, ref, cardToDelete),
    );
  }
}

class _AnimatedCardItem extends ConsumerWidget {
  final CardModel card;
  final List<DuplicateMatch> duplicates;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final void Function(WidgetRef) onDelete;
  final void Function(WidgetRef)? onDuplicateTap;
  final Future<void> Function(WidgetRef) onUndoDismiss;

  const _AnimatedCardItem({
    super.key,
    required this.card,
    required this.duplicates,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onUndoDismiss,
    this.onDuplicateTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AnimatedCardItemInternal(
      card: card,
      duplicates: duplicates,
      onTap: onTap,
      onEdit: onEdit,
      onDelete: () => onDelete(ref),
      onToggleFavorite: () =>
          ref.read(cardListNotifierProvider.notifier).toggleFavorite(card.id),
      onDuplicateTap: onDuplicateTap != null
          ? () => onDuplicateTap!(ref)
          : null,
      onDismissed: () =>
          ref.read(cardListNotifierProvider.notifier).deleteCard(card.id),
      onUndoDismiss: () => onUndoDismiss(ref),
    );
  }
}

class _AnimatedCardItemInternal extends StatefulWidget {
  final CardModel card;
  final List<DuplicateMatch> duplicates;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onDuplicateTap;
  final VoidCallback onDismissed;
  final Future<void> Function() onUndoDismiss;

  const _AnimatedCardItemInternal({
    required this.card,
    required this.duplicates,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onDismissed,
    required this.onUndoDismiss,
    this.onDuplicateTap,
  });

  @override
  State<_AnimatedCardItemInternal> createState() =>
      _AnimatedCardItemInternalState();
}

class _AnimatedCardItemInternalState extends State<_AnimatedCardItemInternal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dismissible(
          key: ValueKey(widget.card.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Card'),
                content: Text(
                  'Are you sure you want to delete "${widget.card.frontText}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            widget.onDismissed();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.card.frontText} deleted'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: widget.onUndoDismiss,
                ),
              ),
            );
          },
          child: CardItemWidget(
            card: widget.card,
            onTap: widget.onTap,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
            onToggleFavorite: widget.onToggleFavorite,
            duplicates: widget.duplicates.isNotEmpty ? widget.duplicates : null,
            onDuplicateTap: widget.onDuplicateTap,
          ),
        ),
      ),
    );
  }
}
