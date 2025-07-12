import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../providers/card_provider.dart';
import '../services/debug_service.dart';

/// Debug menu for development and testing
class DebugMenuScreen extends StatelessWidget {
  const DebugMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show debug menu in debug mode
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Debug Menu'),
        ),
        body: const Center(
          child: Text(
            'Debug menu is only available in debug mode',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Menu'),
        backgroundColor: Colors.red.shade100,
        foregroundColor: Colors.red.shade800,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Warning banner
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.only(bottom: 24.0),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug Mode Only',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This menu is for development and testing purposes.',
                        style: TextStyle(color: Colors.orange.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pre-set card collections
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Pre-set Card Collections',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add pre-made card sets for testing different languages and scenarios.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...DebugService.getDebugCardSets().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _createCardSet(context, entry.key, entry.value),
                          icon: const Icon(Icons.add_circle_outline),
                          label: Text(entry.key),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  
                  // Special button for creating due cards
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _createDueForReviewCards(context),
                      icon: const Icon(Icons.schedule),
                      label: const Text('Create Cards Due for Review'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Data management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage stored data for testing purposes.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Clear all cards
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showClearAllDialog(context),
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      label: const Text(
                        'Clear All Cards',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Show card statistics
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCardStatistics(context),
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Show Card Statistics'),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Mode', 'Debug'),
                  _buildInfoRow('Platform', Theme.of(context).platform.name),
                  _buildInfoRow('Build', kDebugMode ? 'Debug' : 'Release'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _createCardSet(
    BuildContext context,
    String setName,
    List<CardModel> Function() createCards,
  ) async {
    try {
      final cardProvider = context.read<CardProvider>();
      final cards = createCards();
      
      // Add all cards
      for (final card in cards) {
        await cardProvider.addCard(card);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created $setName (${cards.length} cards)'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating cards: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createDueForReviewCards(BuildContext context) async {
    try {
      final cardProvider = context.read<CardProvider>();
      final cards = DebugService.createDueForReviewCards();
      
      // Add all cards
      for (final card in cards) {
        await cardProvider.addCard(card);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created ${cards.length} cards due for review'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating cards: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showClearAllDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Cards'),
        content: const Text(
          'This will permanently delete all cards. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<CardProvider>().clearAllCards();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All cards deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing cards: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCardStatistics(BuildContext context) {
    final cardProvider = context.read<CardProvider>();
    final allCards = cardProvider.allCards;
    
    // Calculate statistics
    final totalCards = allCards.length;
    final languages = allCards.map((c) => c.language).toSet().toList()..sort();
    final categories = allCards.map((c) => c.category).toSet().toList()..sort();
    final reviewedCards = allCards.where((c) => c.reviewCount > 0).length;
    final averageSuccessRate = allCards.isNotEmpty
        ? allCards.map((c) => c.successRate).reduce((a, b) => a + b) / allCards.length
        : 0.0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Card Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Cards', totalCards.toString()),
            _buildStatRow('Reviewed Cards', reviewedCards.toString()),
            _buildStatRow('Average Success Rate', '${averageSuccessRate.toStringAsFixed(1)}%'),
            _buildStatRow('Languages', languages.join(', ')),
            const SizedBox(height: 8),
            const Text('Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...categories.map((category) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text('• $category'),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
