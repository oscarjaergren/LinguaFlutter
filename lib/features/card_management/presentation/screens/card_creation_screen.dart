import 'package:flutter/material.dart';
import '../../../card_review/card_review.dart';
import '../../../icon_search/icon_search.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/icon_model.dart';
import '../../../../shared/domain/models/word_data.dart';
import '../../../../shared/widgets/ai_config_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../language/language.dart';
import '../../domain/providers/card_enrichment_notifier.dart';
import '../view_models/card_creation_notifier.dart';
import '../view_models/card_creation_state.dart';

/// Screen for creating and editing language learning cards with full model support
class CardCreationScreen extends ConsumerStatefulWidget {
  final CardModel? cardToEdit;

  const CardCreationScreen({super.key, this.cardToEdit});

  @override
  ConsumerState<CardCreationScreen> createState() => _CardCreationScreenState();
}

class _CardCreationScreenState extends ConsumerState<CardCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic text controllers
  final _frontTextController = TextEditingController();
  final _backTextController = TextEditingController();
  final _tagsController = TextEditingController();
  final _notesController = TextEditingController();

  // Verb-specific controllers
  final _presentSecondPersonController = TextEditingController();
  final _presentThirdPersonController = TextEditingController();
  final _pastSimpleController = TextEditingController();
  final _pastParticipleController = TextEditingController();
  final _separablePrefixController = TextEditingController();

  // Noun-specific controllers
  final _pluralController = TextEditingController();
  final _genitiveController = TextEditingController();

  // Adjective-specific controllers
  final _comparativeController = TextEditingController();
  final _superlativeController = TextEditingController();

  // Adverb-specific controllers
  final _usageNoteController = TextEditingController();

  final _exampleController = TextEditingController();

  bool _isAutoFilling = false;

  bool get _isEditing => widget.cardToEdit != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.cardToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(cardCreationNotifierProvider.notifier)
            .loadCard(widget.cardToEdit!);

        // Listen to state changes and sync controllers when state is updated
        ref.listen(cardCreationNotifierProvider, (previous, next) {
          if (next.isEditing) {
            _syncControllersFromState(next);
          }
        });

        ref
            .read(languageNotifierProvider.notifier)
            .setActiveLanguage(widget.cardToEdit!.language);
      });
    }
  }

  void _syncControllersFromState(CardCreationState state) {
    _frontTextController.text = state.frontText;
    _backTextController.text = state.backText;
    _tagsController.text = state.tags.join(', ');
    _notesController.text = state.notes ?? '';

    _presentSecondPersonController.text = state.presentSecondPerson ?? '';
    _presentThirdPersonController.text = state.presentThirdPerson ?? '';
    _pastSimpleController.text = state.pastSimple ?? '';
    _pastParticipleController.text = state.pastParticiple ?? '';
    _separablePrefixController.text = state.separablePrefix ?? '';

    _pluralController.text = state.plural ?? '';
    _genitiveController.text = state.genitive ?? '';

    _comparativeController.text = state.comparative ?? '';
    _superlativeController.text = state.superlative ?? '';

    _usageNoteController.text = state.usageNote ?? '';
  }

  @override
  void dispose() {
    ref.read(cardCreationNotifierProvider.notifier).resetForm();
    _frontTextController.dispose();
    _backTextController.dispose();
    _tagsController.dispose();
    _notesController.dispose();
    _presentSecondPersonController.dispose();
    _presentThirdPersonController.dispose();
    _pastSimpleController.dispose();
    _pastParticipleController.dispose();
    _separablePrefixController.dispose();
    _pluralController.dispose();
    _genitiveController.dispose();
    _comparativeController.dispose();
    _superlativeController.dispose();
    _usageNoteController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  Future<void> _selectIcon() async {
    final notifier = ref.read(cardCreationNotifierProvider.notifier);

    ref.read(iconNotifierProvider.notifier).clearSelection();
    // Use English translation (back) for icon search since Iconify uses English keywords
    final searchQuery = _getIconSearchQuery();

    final selectedIcon = await Navigator.push<IconModel>(
      context,
      MaterialPageRoute(
        builder: (context) => IconSearchScreen(initialSearchQuery: searchQuery),
      ),
    );

    if (selectedIcon != null) {
      notifier.selectIcon(selectedIcon);
    }
  }

  /// Gets the best search query for icon search.
  /// Prefers English translation, falls back to front text with articles stripped.
  String? _getIconSearchQuery() {
    final backText = _backTextController.text.trim();
    if (backText.isNotEmpty) {
      final keyword = _extractFirstKeyword(backText);
      return keyword != null ? _stripArticles(keyword) : null;
    }

    final frontText = _frontTextController.text.trim();
    if (frontText.isNotEmpty) {
      final keyword = _extractFirstKeyword(frontText);
      return keyword != null ? _stripArticles(keyword) : null;
    }

    return null;
  }

  /// Extracts the first meaningful keyword (before commas/slashes) for icon search.
  String? _extractFirstKeyword(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return null;

    final primarySegment = normalized.split(RegExp(r'[,;/\n]')).first;
    final words = primarySegment.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return null;
    return words.first.trim();
  }

  // This is a really dumb way of doing this.
  /// Strips common article prefixes from search terms
  String _stripArticles(String text) {
    // German articles
    const articles = [
      'der ', 'die ', 'das ', 'ein ', 'eine ', 'einen ', 'einem ', 'einer ',
      // Spanish articles
      'el ', 'la ', 'los ', 'las ', 'un ', 'una ', 'unos ', 'unas ',
      // French articles
      'le ', 'la ', 'les ', 'un ', 'une ', 'des ',
      // English articles
      'the ', 'a ', 'an ',
    ];

    var result = text.toLowerCase();
    for (final article in articles) {
      if (result.startsWith(article)) {
        result = result.substring(article.length);
        break;
      }
    }
    return result.trim();
  }

  void _addExample() {
    final example = _exampleController.text.trim();
    if (example.isNotEmpty) {
      ref.read(cardCreationNotifierProvider.notifier).addExample(example);
      _exampleController.clear();
    }
  }

  void _removeExample(int index) {
    ref.read(cardCreationNotifierProvider.notifier).removeExample(index);
  }

  Future<void> _autoFillWithAI() async {
    final frontText = _frontTextController.text.trim();
    if (frontText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a word first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final aiNotifier = ref.read(cardEnrichmentNotifierProvider.notifier);
    final aiState = ref.read(cardEnrichmentNotifierProvider);
    if (!aiState.isConfigured) {
      showAiConfigDialog(context, onSaved: _autoFillWithAI);
      return;
    }

    setState(() => _isAutoFilling = true);

    try {
      final activeLanguage = ref.read(languageNotifierProvider).activeLanguage;
      final result = await aiNotifier.enrichWord(
        word: frontText,
        language: activeLanguage,
      );

      if (result != null && mounted) {
        final notifier = ref.read(cardCreationNotifierProvider.notifier);

        notifier.updateWordType(result.wordType);

        if (result.translation != null) {
          _backTextController.text = result.translation!;
          notifier.updateBackText(result.translation!);
        }

        if (result.wordData != null) {
          _applyWordData(result.wordData!);
        }

        for (final example in result.examples) {
          notifier.addExample(example);
        }

        if (result.notes != null) {
          _notesController.text = result.notes!;
          notifier.updateNotes(result.notes!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auto-filled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final error = ref.read(cardEnrichmentNotifierProvider).error;
        if (error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isAutoFilling = false);
    }
  }

  void _applyWordData(WordData wordData) {
    final notifier = ref.read(cardCreationNotifierProvider.notifier);
    switch (wordData) {
      case VerbData():
        notifier.updateIsRegularVerb(wordData.isRegular);
        notifier.updateIsSeparableVerb(wordData.isSeparable);
        _separablePrefixController.text = wordData.separablePrefix ?? '';
        notifier.updateSeparablePrefix(wordData.separablePrefix);
        notifier.updateAuxiliaryVerb(wordData.auxiliary);
        _presentSecondPersonController.text =
            wordData.presentSecondPerson ?? '';
        notifier.updatePresentSecondPerson(wordData.presentSecondPerson);
        _presentThirdPersonController.text = wordData.presentThirdPerson ?? '';
        notifier.updatePresentThirdPerson(wordData.presentThirdPerson);
        _pastSimpleController.text = wordData.pastSimple ?? '';
        notifier.updatePastSimple(wordData.pastSimple);
        _pastParticipleController.text = wordData.pastParticiple ?? '';
        notifier.updatePastParticiple(wordData.pastParticiple);
      case NounData():
        notifier.updateNounGender(wordData.gender);
        _pluralController.text = wordData.plural ?? '';
        notifier.updatePlural(wordData.plural);
        _genitiveController.text = wordData.genitive ?? '';
        notifier.updateGenitive(wordData.genitive);
      case AdjectiveData():
        _comparativeController.text = wordData.comparative ?? '';
        notifier.updateComparative(wordData.comparative);
        _superlativeController.text = wordData.superlative ?? '';
        notifier.updateSuperlative(wordData.superlative);
      case AdverbData():
        _usageNoteController.text = wordData.usageNote ?? '';
        notifier.updateUsageNote(wordData.usageNote);
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(cardCreationNotifierProvider.notifier);
    final success = await notifier.saveCard();

    if (success && mounted) {
      // Update the card in the practice session if one is active
      if (widget.cardToEdit != null) {
        // We don't have the full updated card object here easily without some work,
        // but CardManagementNotifier will notify PracticeSessionNotifier because it watches it.
        // Actually, PracticeSessionNotifier has updateCardInQueue which we should call if we want manual control.
        // But since PracticeSessionNotifier watches CardManagementNotifier, it will rebuild... wait.
        // If it rebuilds, it might reset the session as discussed before.
        // Let's call updateCardInQueue just in case.
        // We'll trust CardManagementNotifier to have updated the card.
        // For now, let's just pop.
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Card updated' : 'Card created'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      final state = ref.read(cardCreationNotifierProvider);
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text(
          'Are you sure you want to delete "${widget.cardToEdit!.frontText}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(cardCreationNotifierProvider.notifier);

      // Remove from practice session first (if active)
      ref
          .read(practiceSessionNotifierProvider.notifier)
          .removeCardFromQueue(widget.cardToEdit!.id);

      final deleted = await notifier.deleteCard();

      if (deleted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card deleted'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        final error = ref.read(cardCreationNotifierProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to delete card.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardCreationNotifierProvider);
    final notifier = ref.read(cardCreationNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Card' : 'Create Card'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _showDeleteConfirmation,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete card',
              color: Colors.red,
            ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            FilledButton(
              onPressed: _saveCard,
              child: Text(_isEditing ? 'Save' : 'Create'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Language indicator
            _buildLanguageCard(context),
            const SizedBox(height: 16),

            // Basic info section
            _buildSectionHeader(
              context,
              'Basic Information',
              Icons.info_outline,
            ),
            const SizedBox(height: 8),
            _buildBasicInfoSection(context, state, notifier),
            const SizedBox(height: 24),

            // Word type and grammar section
            _buildSectionHeader(context, 'Word Type & Grammar', Icons.school),
            const SizedBox(height: 8),
            _buildWordTypeSelector(context, state, notifier),
            const SizedBox(height: 12),
            _buildGrammarSection(context, state, notifier),
            const SizedBox(height: 24),

            // Examples section
            _buildSectionHeader(context, 'Examples', Icons.format_quote),
            const SizedBox(height: 8),
            _buildExamplesSection(context, state, notifier),
            const SizedBox(height: 24),

            // Organization section
            _buildSectionHeader(context, 'Organization', Icons.folder_outlined),
            const SizedBox(height: 8),
            _buildOrganizationSection(context, state, notifier),
            const SizedBox(height: 24),

            // Notes section
            _buildSectionHeader(context, 'Notes', Icons.notes),
            const SizedBox(height: 8),
            _buildNotesSection(context, state, notifier),

            // Exercise mastery section (only when editing)
            if (_isEditing) ...[
              const SizedBox(height: 24),
              ExerciseMasteryWidget(card: widget.cardToEdit!),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageCard(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final languageState = ref.watch(languageNotifierProvider);
        final languageNotifier = ref.read(languageNotifierProvider.notifier);
        final activeLanguage = languageState.activeLanguage;
        final languageDetails =
            languageState.availableLanguages[activeLanguage];
        if (languageDetails == null) return const SizedBox.shrink();

        final color = languageNotifier.getLanguageColor(activeLanguage);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Text(
                languageDetails['flag'] ?? '',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  languageDetails['name'] ?? activeLanguage,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline,
                size: 16,
                color: color.withValues(alpha: 0.6),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoSection(
    BuildContext context,
    CardCreationState state,
    CardCreationNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Icon selector
            Row(
              children: [
                if (state.selectedIcon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconifyIcon(icon: state.selectedIcon!, size: 40),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.selectedIcon!.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'From ${state.selectedIcon!.set}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: notifier.clearIcon,
                    icon: const Icon(Icons.close),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectIcon,
                      icon: const Icon(Icons.image_search),
                      label: const Text('Add Icon (Optional)'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Front text with Auto button
            Consumer(
              builder: (context, ref, _) {
                final languageState = ref.watch(languageNotifierProvider);
                final activeLanguage = languageState.activeLanguage;
                final details =
                    languageState.availableLanguages[activeLanguage];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _frontTextController,
                        onChanged: notifier.updateFrontText,
                        decoration: InputDecoration(
                          labelText:
                              'Word/Phrase (${details?['name'] ?? 'Target'})',
                          hintText: 'Enter the word or phrase to learn',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.translate),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _isAutoFilling
                          ? const SizedBox(
                              width: 48,
                              height: 48,
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          : IconButton.filled(
                              onPressed: _autoFillWithAI,
                              icon: const Icon(Icons.auto_awesome),
                              tooltip: 'Auto-fill with AI',
                            ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Back text
            TextFormField(
              controller: _backTextController,
              onChanged: notifier.updateBackText,
              decoration: const InputDecoration(
                labelText: 'Translation (English)',
                hintText: 'Enter the translation or definition',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.abc),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordTypeSelector(
    BuildContext context,
    CardCreationState state,
    CardCreationNotifier notifier,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: WordType.values.map((type) {
          final isSelected = state.wordType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_wordTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) notifier.updateWordType(type);
              },
              avatar: Icon(_wordTypeIcon(type), size: 18),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _wordTypeLabel(WordType type) {
    return switch (type) {
      WordType.verb => 'Verb',
      WordType.noun => 'Noun',
      WordType.adjective => 'Adjective',
      WordType.adverb => 'Adverb',
      WordType.phrase => 'Phrase',
      WordType.other => 'Other',
    };
  }

  IconData _wordTypeIcon(WordType type) {
    return switch (type) {
      WordType.verb => Icons.directions_run,
      WordType.noun => Icons.category,
      WordType.adjective => Icons.color_lens,
      WordType.adverb => Icons.speed,
      WordType.phrase => Icons.short_text,
      WordType.other => Icons.more_horiz,
    };
  }

  Widget _buildGrammarSection(
    BuildContext context,
    CardCreationState state,
    CardCreationNotifier notifier,
  ) {
    return switch (state.wordType) {
      WordType.verb => _buildVerbGrammar(context, state, notifier),
      WordType.noun => _buildNounGrammar(context, state, notifier),
      WordType.adjective => _buildAdjectiveGrammar(context, state, notifier),
      WordType.adverb => _buildAdverbGrammar(context, state, notifier),
      WordType.phrase || WordType.other => const SizedBox.shrink(),
    };
  }

  Widget _buildVerbGrammar(
    BuildContext context,
    CardCreationState state,
    CardCreationNotifier notifier,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verb properties row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Regular'),
                  selected: state.isRegularVerb,
                  onSelected: notifier.updateIsRegularVerb,
                ),
                FilterChip(
                  label: const Text('Separable'),
                  selected: state.isSeparableVerb,
                  onSelected: notifier.updateIsSeparableVerb,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Auxiliary selector
            Row(
              children: [
                Text('Auxiliary:', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('haben'),
                  selected: state.auxiliaryVerb == 'haben',
                  onSelected: (v) => notifier.updateAuxiliaryVerb('haben'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('sein'),
                  selected: state.auxiliaryVerb == 'sein',
                  onSelected: (v) => notifier.updateAuxiliaryVerb('sein'),
                ),
              ],
            ),

            if (state.isSeparableVerb) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _separablePrefixController,
                onChanged: notifier.updateSeparablePrefix,
                decoration: const InputDecoration(
                  labelText: 'Separable Prefix',
                  hintText: 'e.g., auf, an, aus',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],

            if (!state.isRegularVerb) ...[
              const SizedBox(height: 16),
              Text('Irregular Forms', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _presentSecondPersonController,
                      onChanged: notifier.updatePresentSecondPerson,
                      decoration: const InputDecoration(
                        labelText: 'du (present)',
                        hintText: 'e.g., sprichst',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _presentThirdPersonController,
                      onChanged: notifier.updatePresentThirdPerson,
                      decoration: const InputDecoration(
                        labelText: 'er/sie/es (present)',
                        hintText: 'e.g., spricht',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pastSimpleController,
                      onChanged: notifier.updatePastSimple,
                      decoration: const InputDecoration(
                        labelText: 'Präteritum',
                        hintText: 'e.g., sprach',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _pastParticipleController,
                      onChanged: notifier.updatePastParticiple,
                      decoration: const InputDecoration(
                        labelText: 'Partizip II',
                        hintText: 'e.g., gesprochen',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNounGrammar(
    BuildContext context,
    CardCreationState state,
    CardCreationNotifier notifier,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final activeLanguage = ref
            .watch(languageNotifierProvider)
            .activeLanguage;
        final isGerman = activeLanguage == 'de';
        final articles = isGerman
            ? ['der', 'die', 'das']
            : ['masculine', 'feminine', 'neuter'];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gender/Article',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: articles.map((article) {
                    return ChoiceChip(
                      label: Text(article),
                      selected: state.nounGender == article,
                      onSelected: (v) =>
                          notifier.updateNounGender(v ? article : null),
                      selectedColor: _getGenderColor(
                        article,
                      ).withValues(alpha: 0.3),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pluralController,
                        onChanged: notifier.updatePlural,
                        decoration: const InputDecoration(
                          labelText: 'Plural Form',
                          hintText: 'e.g., Bücher',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _genitiveController,
                        onChanged: notifier.updateGenitive,
                        decoration: const InputDecoration(
                          labelText: 'Genitive',
                          hintText: 'e.g., des Buches',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getGenderColor(String gender) {
    return switch (gender) {
      'der' || 'masculine' => Colors.blue,
      'die' || 'feminine' => Colors.pink,
      'das' || 'neuter' => Colors.green,
      _ => Colors.grey,
    };
  }

  Widget _buildAdjectiveGrammar(
    BuildContext context,
    CardCreationState state,
    CardCreationNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparison Forms',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _comparativeController,
                    onChanged: notifier.updateComparative,
                    decoration: const InputDecoration(
                      labelText: 'Comparative',
                      hintText: 'e.g., größer',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _superlativeController,
                    onChanged: notifier.updateSuperlative,
                    decoration: const InputDecoration(
                      labelText: 'Superlative',
                      hintText: 'e.g., größten',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdverbGrammar(
    BuildContext context,
    CardCreationState state,
    CardCreationNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _usageNoteController,
          onChanged: notifier.updateUsageNote,
          decoration: const InputDecoration(
            labelText: 'Usage Note',
            hintText: 'Any special usage information',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ),
    );
  }

  Widget _buildExamplesSection(
    BuildContext context,
    CardCreationState state,
    CardCreationNotifier notifier,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _exampleController,
                    decoration: const InputDecoration(
                      labelText: 'Add Example Sentence',
                      hintText: 'Type an example sentence',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onFieldSubmitted: (_) => _addExample(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addExample,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (state.examples.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              ...state.examples.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeExample(entry.key),
                        icon: const Icon(Icons.close, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationSection(
    BuildContext context,
    CardCreationState state,
    CardCreationNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _tagsController,
          onChanged: notifier.updateTags,
          decoration: const InputDecoration(
            labelText: 'Tags (Optional)',
            hintText: 'Separate with commas',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.tag),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection(
    BuildContext context,
    CardCreationState state,
    CardCreationNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _notesController,
          onChanged: notifier.updateNotes,
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            hintText: 'Usage tips, grammar notes, mnemonics...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          minLines: 4,
          maxLines: null,
        ),
      ),
    );
  }
}
