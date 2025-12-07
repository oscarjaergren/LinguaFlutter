import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/navigation/app_router.dart';
import '../../../duplicate_detection/duplicate_detection.dart';
import '../../../language/domain/language_provider.dart';
import '../../../mascot/domain/mascot_provider.dart';
import '../../../streak/presentation/widgets/streak_status_widget.dart';
import '../../domain/providers/card_management_provider.dart';
import '../view_models/card_list_view_model.dart';
import '../widgets/card_list_view.dart';

/// Screen for displaying and managing the list of cards
class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reset mascot session when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MascotProvider>().resetSession();
    });

    return ChangeNotifierProvider(
      create: (context) => CardListViewModel(
        cardManagement: context.read<CardManagementProvider>(),
        duplicateDetection: context.read<DuplicateDetectionProvider>(),
        languageProvider: context.read<LanguageProvider>(),
      ),
      child: Consumer<CardListViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: _buildLanguageSelector(context),
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
                Expanded(
                  child: CardListView(viewModel: viewModel),
                ),
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

  Widget _buildLanguageSelector(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final activeLanguage = languageProvider.activeLanguage;
        final languageDetails = languageProvider.getLanguageDetails(activeLanguage)!;

        return PopupMenuButton<String>(
          onSelected: (String languageCode) {
            languageProvider.setActiveLanguage(languageCode);
            // CardManagementProvider listens to LanguageProvider automatically
          },
          itemBuilder: (BuildContext context) {
            return languageProvider.availableLanguages.entries.map((entry) {
              final code = entry.key;
              final details = entry.value;
              return PopupMenuItem<String>(
                value: code,
                child: Row(
                  children: [
                    Text(
                      details['flag'],
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(details['name']),
                    if (code == activeLanguage) ...[
                      const Spacer(),
                      Icon(
                        Icons.check,
                        color: languageProvider.getLanguageColor(code),
                        size: 16,
                      ),
                    ],
                  ],
                ),
              );
            }).toList();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                languageDetails['flag'],
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                languageDetails['name'],
                style: TextStyle(
                  color: languageProvider.getLanguageColor(activeLanguage),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: languageProvider.getLanguageColor(activeLanguage),
              ),
            ],
          ),
        );
      },
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
