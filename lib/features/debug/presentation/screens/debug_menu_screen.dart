import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../shared/services/google_cloud_tts_service.dart';
import '../../../../shared/services/tts_service.dart';
import '../../../../shared/services/elevenlabs_tts_service.dart';
import '../../../../shared/services/logger_service.dart';
import 'package:provider/provider.dart';
import '../../../card_management/card_management.dart';
import '../../../debug/data/debug_service.dart';
import '../../../language/language.dart';

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
          // Create test cards
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Test Cards',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create cards in the currently selected language for testing.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick sets
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _createCards(context, 10),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create 10 Cards'),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _createCards(context, 20),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create 20 Cards'),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _createCards(context, 30),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create 30 Cards'),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  
                  // Special button for creating due cards
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _createDueCards(context, 5),
                      icon: const Icon(Icons.schedule),
                      label: const Text('Create 5 Cards Due for Review'),
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

          // German vocabulary from JSON
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.translate, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'German Vocabulary (JSON)',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Load real German vocabulary cards from JSON file with proper scheduling.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Load all German words - Available Now
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _loadGermanWords(context, null, makeAvailableNow: true),
                      icon: const Icon(Icons.library_books),
                      label: const Text('Load All German Words (Available Now)'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Load 10 German words - Available Now
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _loadGermanWords(context, 10, makeAvailableNow: true),
                      icon: const Icon(Icons.book),
                      label: const Text('Load 10 Words (Available Now)'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue.shade700),
                        foregroundColor: Colors.blue.shade700,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Load 25 German words - Available Now
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _loadGermanWords(context, 25, makeAvailableNow: true),
                      icon: const Icon(Icons.book),
                      label: const Text('Load 25 Words (Available Now)'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue.shade700),
                        foregroundColor: Colors.blue.shade700,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  Text(
                    '⏰ Scheduled Review Times',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Load with original spaced repetition schedule.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Load with scheduled times
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _loadGermanWords(context, 10, makeAvailableNow: false),
                      icon: const Icon(Icons.schedule),
                      label: const Text('Load 10 Words (Scheduled)'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.orange.shade700),
                        foregroundColor: Colors.orange.shade700,
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

          // TTS Provider Selector
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.volume_up, color: Colors.purple.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Text-to-Speech Provider',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Consumer<CardManagementProvider>(
                    builder: (context, cardManagement, child) {
                      final ttsService = GoogleCloudTtsService();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current: ${ttsService.isGoogleTtsEnabled ? "Google Cloud Neural2 ⭐⭐⭐⭐⭐" : "Native Platform TTS ⭐⭐"}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ttsService.isGoogleTtsEnabled ? Colors.green : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Test different TTS engines:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _testTts(context, TtsProviderType.native),
                                  icon: const Icon(Icons.volume_up_outlined),
                                  label: const Text('Native'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(color: Colors.orange),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _testTts(context, TtsProviderType.google),
                                  icon: const Icon(Icons.volume_up),
                                  label: const Text('Google'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    side: const BorderSide(color: Colors.green),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _testTts(context, TtsProviderType.elevenLabs),
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('ElevenLabs (Ultra-Realistic)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.purple,
                                side: const BorderSide(color: Colors.purple),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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

  Future<void> _createCards(BuildContext context, int count) async {
    try {
      final cardManagement = context.read<CardManagementProvider>();
      final languageProvider = context.read<LanguageProvider>();
      
      // Get active language or default to 'en'
      final language = languageProvider.activeLanguage.isEmpty 
          ? 'en' 
          : languageProvider.activeLanguage;
      
      final cards = DebugService.createBasicCards(language, count);
      
      // Batch add all cards
      await cardManagement.addMultipleCards(cards);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created $count test cards in ${language.toUpperCase()}'),
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

  Future<void> _createDueCards(BuildContext context, int count) async {
    try {
      final cardManagement = context.read<CardManagementProvider>();
      final languageProvider = context.read<LanguageProvider>();
      
      // Get active language or default to 'en'
      final language = languageProvider.activeLanguage.isEmpty 
          ? 'en' 
          : languageProvider.activeLanguage;
      
      final cards = DebugService.createDueForReviewCards(language, count);
      
      // Batch add all cards
      await cardManagement.addMultipleCards(cards);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created $count cards due for review in ${language.toUpperCase()}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'REVIEW',
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

  Future<void> _loadGermanWords(
    BuildContext context, 
    int? limit, {
    bool makeAvailableNow = true,
  }) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Loading German vocabulary${limit != null ? ' ($limit cards)' : ''}...'),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      final cardManagement = context.read<CardManagementProvider>();
      final languageProvider = context.read<LanguageProvider>();
      
      // Set active language to German
      languageProvider.setActiveLanguage('de');
      
      // Load German words from JSON
      LoggerService.debug('Calling loadGermanWordsFromJson with limit=$limit, makeAvailableNow=$makeAvailableNow');
      final cards = await DebugService.loadGermanWordsFromJson(
        limit: limit,
        makeAvailableNow: makeAvailableNow,
      );
      
      LoggerService.debug('Received ${cards.length} cards from service');
      
      // Batch add all cards
      await cardManagement.addMultipleCards(cards);
      
      final availabilityText = makeAvailableNow 
          ? 'available now for review' 
          : 'scheduled for future review';
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Loaded ${cards.length} German vocabulary cards ($availabilityText)!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      LoggerService.error('Error in _loadGermanWords', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading German words: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
        await context.read<CardManagementProvider>().clearAllCards();
        
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
    final cardManagement = context.read<CardManagementProvider>();
    final allCards = cardManagement.allCards;
    
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

  Future<void> _testTts(BuildContext context, TtsProviderType provider) async {
    final testPhrase = 'Guten Tag! Das ist ein Test.';
    
    try {
      switch (provider) {
        case TtsProviderType.native:
          LoggerService.debug('Testing Native TTS...');
          final nativeTts = NativeTtsService();
          await nativeTts.initialize();
          await nativeTts.speak(testPhrase, 'de');
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔊 Playing Native platform TTS'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
          
        case TtsProviderType.google:
          LoggerService.debug('Testing Google Cloud TTS...');
          final googleTts = GoogleCloudTtsService();
          await googleTts.initialize();
          await googleTts.speak(testPhrase, 'de');
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎙️ Playing Google Cloud Neural2 voice'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
          
        case TtsProviderType.elevenLabs:
          LoggerService.debug('Testing ElevenLabs TTS...');
          final elevenLabsTts = ElevenLabsTtsService();
          await elevenLabsTts.initialize();
          await elevenLabsTts.speak(testPhrase, 'de');
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✨ Playing ElevenLabs ultra-realistic voice'),
                backgroundColor: Colors.purple,
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
      }
    } catch (e) {
      LoggerService.error('TTS test error', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

enum TtsProviderType {
  native,
  google,
  elevenLabs,
}
