import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/navigation/app_router.dart';
import '../../../duplicate_detection/duplicate_detection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../language/language.dart';
import '../../../mascot/domain/mascot_notifier.dart';
import '../../../streak/presentation/widgets/streak_status_widget.dart';
import '../../domain/providers/card_management_provider.dart';
import '../view_models/card_list_view_model.dart';
import '../widgets/card_list_view.dart';

import '../../../dashboard/presentation/widgets/language_selector_widget.dart';

/// Screen for displaying and managing the list of cards
class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reset mascot session when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mascotNotifierProvider.notifier).resetSession();
    });

    return ChangeNotifierProvider(
      create: (context) => CardListViewModel(
        cardManagement: context.read<CardManagementProvider>(),
        getActiveLanguage: () =>
            ref.read(languageNotifierProvider).activeLanguage,
        getLanguageDetails: ref
            .read(languageNotifierProvider.notifier)
            .getLanguageDetails,
      ),
      child: Consumer<CardListViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const LanguageSelectorWidget(),
              actions: [
                // Search button
                if (!viewModel.isSearching)
                  IconButton(
                    onPressed: viewModel.startSearch,
                    icon: const Icon(Icons.search),
                  ),
                // Filter button
                IconButton(
                  onPressed: () => _showFilterDialog(context, viewModel),
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
                Expanded(child: CardListView(viewModel: viewModel)),
              ],
            ),
            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Review button
                if (viewModel.canStartReview)
                  FloatingActionButton.extended(
                    onPressed: () => _startReview(context),
                    heroTag: 'review',
                    icon: const Icon(Icons.quiz),
                    label: Text('Review (${viewModel.cardsToReview})'),
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
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext context, CardListViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Show only due cards'),
              value: viewModel.showOnlyDue,
              onChanged: (_) => viewModel.toggleShowOnlyDue(),
            ),
            CheckboxListTile(
              title: const Text('Show only favorites'),
              value: viewModel.showOnlyFavorites,
              onChanged: (_) => viewModel.toggleShowOnlyFavorites(),
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
              viewModel.clearAllFilters();
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
