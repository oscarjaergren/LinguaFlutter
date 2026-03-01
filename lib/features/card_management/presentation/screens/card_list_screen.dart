import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/navigation/app_router.dart';
import '../../../dashboard/presentation/widgets/language_selector_widget.dart';
import '../../../mascot/domain/mascot_notifier.dart';
import '../../../streak/presentation/widgets/streak_status_widget.dart';
import '../../domain/providers/card_management_notifier.dart';
import '../../domain/providers/card_management_state.dart';
import '../view_models/card_list_notifier.dart';
import '../widgets/card_list_view.dart';

/// Screen for displaying and managing the list of cards
class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reset mascot session when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mascotNotifierProvider.notifier).resetSession();
    });

    final listState = ref.watch(cardListNotifierProvider);
    final listNotifier = ref.read(cardListNotifierProvider.notifier);
    final managementState = ref.watch(cardManagementNotifierProvider);
    final dueCount = managementState.dueCount;

    return Scaffold(
      appBar: AppBar(
        title: const LanguageSelectorWidget(),
        actions: [
          // Search button
          if (!listState.isSearching)
            IconButton(
              onPressed: listNotifier.toggleSearch,
              icon: const Icon(Icons.search),
            ),
          // Filter button
          IconButton(
            onPressed: () => _showFilterDialog(context, ref),
            icon: const Icon(Icons.filter_list),
          ),
          // Debug menu
          if (kDebugMode)
            IconButton(
              onPressed: () => context.pushDebug(),
              icon: const Icon(Icons.bug_report),
            ),
        ],
      ),
      body: Column(
        children: [
          // Streak status
          const StreakStatusWidget(),
          // Main content
          const Expanded(child: CardListView()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Review button
          FloatingActionButton.extended(
            onPressed: () => _startReview(context),
            heroTag: 'review',
            icon: const Icon(Icons.quiz),
            label: Text(dueCount > 0 ? 'Review ($dueCount)' : 'Review'),
          ),
          const SizedBox(height: 16),
          // Add card button
          FloatingActionButton(
            onPressed: () => _createNewCard(context),
            heroTag: 'add',
            child: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    final managementState = ref.watch(cardManagementNotifierProvider);
    final managementNotifier = ref.read(
      cardManagementNotifierProvider.notifier,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Show only due cards'),
              value: managementState.showOnlyDue,
              onChanged: (_) => managementNotifier.toggleShowOnlyDue(),
            ),
            CheckboxListTile(
              title: const Text('Show only favorites'),
              value: managementState.showOnlyFavorites,
              onChanged: (_) => managementNotifier.toggleShowOnlyFavorites(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              managementNotifier.clearAllFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _startReview(BuildContext context) {
    context.pushPractice();
  }

  void _createNewCard(BuildContext context) {
    context.pushCardCreation();
  }
}
