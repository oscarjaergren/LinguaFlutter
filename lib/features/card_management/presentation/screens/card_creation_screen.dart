import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../card_review/domain/providers/practice_session_provider.dart';
import '../../../card_review/presentation/widgets/exercise_mastery_widget.dart';
import '../../../icon_search/icon_search.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/icon_model.dart';
import '../../../../shared/domain/models/word_data.dart';
import '../../../../shared/services/ai/ai.dart';
import '../../../language/domain/language_provider.dart';
import '../../domain/providers/card_management_provider.dart';
import '../../domain/providers/card_enrichment_provider.dart';

/// Screen for creating and editing language learning cards with full model support
class CreationCreationScreen extends StatefulWidget {
  final CardModel? cardToEdit;

  const CreationCreationScreen({super.key, this.cardToEdit});

  @override
  State<CreationCreationScreen> createState() => _CreationCreationScreenState();
}

class _CreationCreationScreenState extends State<CreationCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic text controllers
  final _frontTextController = TextEditingController();
  final _backTextController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  final _notesController = TextEditingController();

  // Verb-specific controllers
  final _presentDuController = TextEditingController();
  final _presentErController = TextEditingController();
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

  // State
  IconModel? _selectedIcon;
  bool _isLoading = false;
  bool _isAutoFilling = false;
  WordType _selectedWordType = WordType.other;
  List<String> _examples = [];
  final _exampleController = TextEditingController();

  // Verb state
  bool _isRegularVerb = true;
  bool _isSeparableVerb = false;
  String _auxiliaryVerb = 'haben';

  // Noun state
  String? _nounGender;

  bool get _isEditing => widget.cardToEdit != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.cardToEdit != null) {
      final card = widget.cardToEdit!;
      _frontTextController.text = card.frontText;
      _backTextController.text = card.backText;
      _categoryController.text = card.category;
      _tagsController.text = card.tags.join(', ');
      _selectedIcon = card.icon;
      _notesController.text = card.notes ?? '';
      _examples = List.from(card.examples);

      // Initialize word data
      if (card.wordData != null) {
        _initializeWordData(card.wordData!);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<LanguageProvider>().setActiveLanguage(card.language);
      });
    }
  }

  void _initializeWordData(WordData wordData) {
    switch (wordData) {
      case VerbData():
        _selectedWordType = WordType.verb;
        _isRegularVerb = wordData.isRegular;
        _isSeparableVerb = wordData.isSeparable;
        _separablePrefixController.text = wordData.separablePrefix ?? '';
        _auxiliaryVerb = wordData.auxiliary;
        _presentDuController.text = wordData.presentDu ?? '';
        _presentErController.text = wordData.presentEr ?? '';
        _pastSimpleController.text = wordData.pastSimple ?? '';
        _pastParticipleController.text = wordData.pastParticiple ?? '';
      case NounData():
        _selectedWordType = WordType.noun;
        _nounGender = wordData.gender;
        _pluralController.text = wordData.plural ?? '';
        _genitiveController.text = wordData.genitive ?? '';
      case AdjectiveData():
        _selectedWordType = WordType.adjective;
        _comparativeController.text = wordData.comparative ?? '';
        _superlativeController.text = wordData.superlative ?? '';
      case AdverbData():
        _selectedWordType = WordType.adverb;
        _usageNoteController.text = wordData.usageNote ?? '';
    }
  }

  @override
  void dispose() {
    _frontTextController.dispose();
    _backTextController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _notesController.dispose();
    _presentDuController.dispose();
    _presentErController.dispose();
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

  WordData? _buildWordData() {
    switch (_selectedWordType) {
      case WordType.verb:
        return WordData.verb(
          isRegular: _isRegularVerb,
          isSeparable: _isSeparableVerb,
          separablePrefix: _separablePrefixController.text.trim().isNotEmpty
              ? _separablePrefixController.text.trim()
              : null,
          auxiliary: _auxiliaryVerb,
          presentDu: _presentDuController.text.trim().isNotEmpty
              ? _presentDuController.text.trim()
              : null,
          presentEr: _presentErController.text.trim().isNotEmpty
              ? _presentErController.text.trim()
              : null,
          pastSimple: _pastSimpleController.text.trim().isNotEmpty
              ? _pastSimpleController.text.trim()
              : null,
          pastParticiple: _pastParticipleController.text.trim().isNotEmpty
              ? _pastParticipleController.text.trim()
              : null,
        );
      case WordType.noun:
        if (_nounGender == null) return null;
        return WordData.noun(
          gender: _nounGender!,
          plural: _pluralController.text.trim().isNotEmpty
              ? _pluralController.text.trim()
              : null,
          genitive: _genitiveController.text.trim().isNotEmpty
              ? _genitiveController.text.trim()
              : null,
        );
      case WordType.adjective:
        return WordData.adjective(
          comparative: _comparativeController.text.trim().isNotEmpty
              ? _comparativeController.text.trim()
              : null,
          superlative: _superlativeController.text.trim().isNotEmpty
              ? _superlativeController.text.trim()
              : null,
        );
      case WordType.adverb:
        return WordData.adverb(
          usageNote: _usageNoteController.text.trim().isNotEmpty
              ? _usageNoteController.text.trim()
              : null,
        );
      case WordType.phrase:
      case WordType.other:
        return null;
    }
  }

  Future<void> _selectIcon() async {
    context.read<IconProvider>().clearSelection();
    // Use English translation (back) for icon search since Iconify uses English keywords
    final searchQuery = _getIconSearchQuery();

    final selectedIcon = await Navigator.push<IconModel>(
      context,
      MaterialPageRoute(
        builder: (context) => IconSearchScreen(initialSearchQuery: searchQuery),
      ),
    );

    if (selectedIcon != null) {
      setState(() => _selectedIcon = selectedIcon);
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
      setState(() {
        _examples.add(example);
        _exampleController.clear();
      });
    }
  }

  void _removeExample(int index) {
    setState(() => _examples.removeAt(index));
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

    final aiProvider = context.read<CardEnrichmentProvider>();
    if (!aiProvider.isConfigured) {
      _showApiKeyDialog();
      return;
    }

    setState(() => _isAutoFilling = true);

    try {
      final languageProvider = context.read<LanguageProvider>();
      final result = await aiProvider.enrichWord(
        word: frontText,
        language: languageProvider.activeLanguage,
      );

      if (result != null && mounted) {
        setState(() {
          // Set word type
          _selectedWordType = result.wordType;

          // Set translation from AI result (override existing)
          if (result.translation != null) {
            _backTextController.text = result.translation!;
          }

          // Set word-specific data
          if (result.wordData != null) {
            _applyWordData(result.wordData!);
          }

          // Add examples
          if (result.examples.isNotEmpty) {
            _examples = List.from(result.examples);
          }

          // Set notes
          if (result.notes != null && _notesController.text.isEmpty) {
            _notesController.text = result.notes!;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auto-filled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (aiProvider.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI Error: ${aiProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAutoFilling = false);
    }
  }

  void _applyWordData(WordData wordData) {
    switch (wordData) {
      case VerbData():
        _isRegularVerb = wordData.isRegular;
        _isSeparableVerb = wordData.isSeparable;
        _separablePrefixController.text = wordData.separablePrefix ?? '';
        _auxiliaryVerb = wordData.auxiliary;
        _presentDuController.text = wordData.presentDu ?? '';
        _presentErController.text = wordData.presentEr ?? '';
        _pastSimpleController.text = wordData.pastSimple ?? '';
        _pastParticipleController.text = wordData.pastParticiple ?? '';
      case NounData():
        _nounGender = wordData.gender;
        _pluralController.text = wordData.plural ?? '';
        _genitiveController.text = wordData.genitive ?? '';
      case AdjectiveData():
        _comparativeController.text = wordData.comparative ?? '';
        _superlativeController.text = wordData.superlative ?? '';
      case AdverbData():
        _usageNoteController.text = wordData.usageNote ?? '';
    }
  }

  void _showApiKeyDialog() {
    final keyController = TextEditingController();
    final aiProvider = context.read<CardEnrichmentProvider>();
    var selectedProvider = AiProvider.gemini; // Default to Gemini (free tier)
    var selectedModel = selectedProvider.defaultModel;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('AI Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a provider and enter your API key.\n'
                  'Gemini offers a free tier - get a key at ai.google.dev',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AiProvider>(
                  value: selectedProvider,
                  decoration: const InputDecoration(
                    labelText: 'Provider',
                    border: OutlineInputBorder(),
                  ),
                  items: AiProvider.values
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedProvider = value;
                        selectedModel = value.defaultModel;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedModel,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    border: OutlineInputBorder(),
                  ),
                  items: selectedProvider.availableModels
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedModel = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: selectedProvider == AiProvider.gemini
                        ? 'AIza...'
                        : 'sk-...',
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (keyController.text.trim().isNotEmpty) {
                  await aiProvider.setProvider(selectedProvider);
                  await aiProvider.setModel(selectedModel);
                  await aiProvider.setApiKey(keyController.text.trim());
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    _autoFillWithAI();
                  }
                }
              },
              child: const Text('Save & Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cardManagement = context.read<CardManagementProvider>();
      final languageProvider = context.read<LanguageProvider>();
      final activeLanguage = languageProvider.activeLanguage;

      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final wordData = _buildWordData();

      if (_isEditing) {
        final updatedCard = widget.cardToEdit!.copyWith(
          frontText: _frontTextController.text.trim(),
          backText: _backTextController.text.trim(),
          icon: _selectedIcon,
          language: activeLanguage,
          category: _categoryController.text.trim(),
          tags: tags,
          wordData: wordData,
          examples: _examples,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          updatedAt: DateTime.now(),
        );
        await cardManagement.saveCard(updatedCard);

        // Update the card in the practice session if one is active
        if (mounted) {
          context.read<PracticeSessionProvider>().updateCardInQueue(
            updatedCard,
          );
        }
      } else {
        final newCard =
            CardModel.create(
              frontText: _frontTextController.text.trim(),
              backText: _backTextController.text.trim(),
              icon: _selectedIcon,
              language: activeLanguage,
              category: _categoryController.text.trim(),
              tags: tags,
            ).copyWith(
              wordData: wordData,
              examples: _examples,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            );

        await cardManagement.saveCard(newCard);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Card updated' : 'Card created'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      try {
        final cardId = widget.cardToEdit!.id;

        // Remove from practice session first (if active)
        context.read<PracticeSessionProvider>().removeCardFromQueue(cardId);

        // Then delete from storage
        await context.read<CardManagementProvider>().deleteCard(cardId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Card deleted'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting card: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          if (_isLoading)
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
            _buildBasicInfoSection(context),
            const SizedBox(height: 24),

            // Word type and grammar section
            _buildSectionHeader(context, 'Word Type & Grammar', Icons.school),
            const SizedBox(height: 8),
            _buildWordTypeSelector(context),
            const SizedBox(height: 12),
            _buildGrammarSection(context),
            const SizedBox(height: 24),

            // Examples section
            _buildSectionHeader(context, 'Examples', Icons.format_quote),
            const SizedBox(height: 8),
            _buildExamplesSection(context),
            const SizedBox(height: 24),

            // Organization section
            _buildSectionHeader(context, 'Organization', Icons.folder_outlined),
            const SizedBox(height: 8),
            _buildOrganizationSection(context),
            const SizedBox(height: 24),

            // Notes section
            _buildSectionHeader(context, 'Notes', Icons.notes),
            const SizedBox(height: 8),
            _buildNotesSection(context),

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
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final activeLanguage = languageProvider.activeLanguage;
        final languageDetails = languageProvider.getLanguageDetails(
          activeLanguage,
        );
        if (languageDetails == null) return const SizedBox.shrink();

        final color = languageProvider.getLanguageColor(activeLanguage);

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

  Widget _buildBasicInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Icon selector
            Row(
              children: [
                if (_selectedIcon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconifyIcon(icon: _selectedIcon!, size: 40),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedIcon!.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'From ${_selectedIcon!.set}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedIcon = null),
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
            Consumer<LanguageProvider>(
              builder: (context, lp, _) {
                final details = lp.getLanguageDetails(lp.activeLanguage);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _frontTextController,
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

  Widget _buildWordTypeSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: WordType.values.map((type) {
          final isSelected = _selectedWordType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_wordTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedWordType = type);
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

  Widget _buildGrammarSection(BuildContext context) {
    return switch (_selectedWordType) {
      WordType.verb => _buildVerbGrammar(context),
      WordType.noun => _buildNounGrammar(context),
      WordType.adjective => _buildAdjectiveGrammar(context),
      WordType.adverb => _buildAdverbGrammar(context),
      WordType.phrase || WordType.other => const SizedBox.shrink(),
    };
  }

  Widget _buildVerbGrammar(BuildContext context) {
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
                  selected: _isRegularVerb,
                  onSelected: (v) => setState(() => _isRegularVerb = v),
                ),
                FilterChip(
                  label: const Text('Separable'),
                  selected: _isSeparableVerb,
                  onSelected: (v) => setState(() => _isSeparableVerb = v),
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
                  selected: _auxiliaryVerb == 'haben',
                  onSelected: (v) => setState(() => _auxiliaryVerb = 'haben'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('sein'),
                  selected: _auxiliaryVerb == 'sein',
                  onSelected: (v) => setState(() => _auxiliaryVerb = 'sein'),
                ),
              ],
            ),

            if (_isSeparableVerb) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _separablePrefixController,
                decoration: const InputDecoration(
                  labelText: 'Separable Prefix',
                  hintText: 'e.g., auf, an, aus',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],

            if (!_isRegularVerb) ...[
              const SizedBox(height: 16),
              Text('Irregular Forms', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _presentDuController,
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
                      controller: _presentErController,
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

  Widget _buildNounGrammar(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isGerman = languageProvider.activeLanguage == 'de';
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
                      selected: _nounGender == article,
                      onSelected: (v) =>
                          setState(() => _nounGender = v ? article : null),
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

  Widget _buildAdjectiveGrammar(BuildContext context) {
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

  Widget _buildAdverbGrammar(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _usageNoteController,
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

  Widget _buildExamplesSection(BuildContext context) {
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
            if (_examples.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              ..._examples.asMap().entries.map((entry) {
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

  Widget _buildOrganizationSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g., Vocabulary, Grammar, A1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (Optional)',
                hintText: 'Separate with commas',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            hintText: 'Usage tips, grammar notes, mnemonics...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
      ),
    );
  }
}
