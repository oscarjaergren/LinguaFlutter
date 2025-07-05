import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../models/icon_model.dart';
import '../providers/card_provider.dart';
import '../providers/language_provider.dart';
import '../providers/icon_provider.dart';
import '../widgets/iconify_icon.dart';
import 'icon_search_screen.dart';

/// Simple screen for creating and editing language learning cards
class SimpleCardCreationScreen extends StatefulWidget {
  final CardModel? cardToEdit;
  
  const SimpleCardCreationScreen({
    super.key,
    this.cardToEdit,
  });

  @override
  State<SimpleCardCreationScreen> createState() => _SimpleCardCreationScreenState();
}

class _SimpleCardCreationScreenState extends State<SimpleCardCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _frontTextController = TextEditingController();
  final _backTextController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  
  IconModel? _selectedIcon;
  bool _isLoading = false;
  String? _germanArticle; // For German nouns: der, die, das

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
      _germanArticle = card.germanArticle;
      
      // Set the language in the provider to match the card being edited
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<LanguageProvider>().setActiveLanguage(card.language);
      });
    }
  }

  @override
  void dispose() {
    _frontTextController.dispose();
    _backTextController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectIcon() async {
    // Clear any previous selection
    context.read<IconProvider>().clearSelection();
    
    // Get the front text to use as initial search query
    final frontText = _frontTextController.text.trim();
    
    // Navigate to icon search screen with auto-search
    final selectedIcon = await Navigator.push<IconModel>(
      context,
      MaterialPageRoute(
        builder: (context) => IconSearchScreen(
          initialSearchQuery: frontText.isNotEmpty ? frontText : null,
        ),
      ),
    );
    
    // Set the returned icon if one was selected
    if (selectedIcon != null) {
      setState(() {
        _selectedIcon = selectedIcon;
      });
    }
  }

  void _removeIcon() {
    setState(() {
      _selectedIcon = null;
    });
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final cardProvider = context.read<CardProvider>();
      final languageProvider = context.read<LanguageProvider>();
      final activeLanguage = languageProvider.activeLanguage;
      
      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      
      if (widget.cardToEdit != null) {
        // Update existing card
        final updatedCard = widget.cardToEdit!.copyWith(
          frontText: _frontTextController.text.trim(),
          backText: _backTextController.text.trim(),
          icon: _selectedIcon,
          language: activeLanguage,
          category: _categoryController.text.trim(),
          tags: tags,
          germanArticle: activeLanguage == 'de' ? _germanArticle : null,
          updatedAt: DateTime.now(),
        );
        
        await cardProvider.updateCard(updatedCard);
      } else {
        // Create new card
        final newCard = CardModel.create(
          frontText: _frontTextController.text.trim(),
          backText: _backTextController.text.trim(),
          icon: _selectedIcon,
          language: activeLanguage,
          category: _categoryController.text.trim(),
          tags: tags,
          germanArticle: activeLanguage == 'de' ? _germanArticle : null,
        );
        
        await cardProvider.addCard(newCard);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.cardToEdit != null 
                ? 'Card updated successfully' 
                : 'Card created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cardToEdit != null ? 'Edit Card' : 'Create Card'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveCard,
              child: Text(
                widget.cardToEdit != null ? 'UPDATE' : 'CREATE',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Language display (read-only, determined by active language)
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                final activeLanguage = languageProvider.activeLanguage;
                final languageDetails = languageProvider.getLanguageDetails(activeLanguage)!;
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Language',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: languageProvider.getLanguageColor(activeLanguage).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: languageProvider.getLanguageColor(activeLanguage),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                languageDetails['flag'],
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    languageDetails['name'],
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: languageProvider.getLanguageColor(activeLanguage),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Set from home screen',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Icon(
                                Icons.info_outline,
                                color: languageProvider.getLanguageColor(activeLanguage).withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Icon selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Icon (Optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_selectedIcon != null) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconifyIcon(
                              icon: _selectedIcon!,
                              size: 32,
                            ),
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
                            onPressed: _removeIcon,
                            icon: const Icon(Icons.close),
                            tooltip: 'Remove icon',
                          ),
                        ],
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: _selectIcon,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Select Icon'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Front text
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                final activeLanguage = languageProvider.activeLanguage;
                final languageDetails = languageProvider.getLanguageDetails(activeLanguage)!;
                
                return TextFormField(
                  controller: _frontTextController,
                  decoration: InputDecoration(
                    labelText: 'Front Text (${languageDetails['name']})',
                    hintText: 'Enter the word or phrase to learn',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.translate),
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter front text';
                    }
                    return null;
                  },
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // German article selection (only show for German)
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                if (languageProvider.activeLanguage == 'de') {
                  final articles = languageProvider.getLanguageArticles('de');
                  return Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'German Article (Optional)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select the article for German nouns',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: articles.map((article) {
                                  final isSelected = _germanArticle == article;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: FilterChip(
                                      label: Text(article),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _germanArticle = selected ? article : null;
                                        });
                                      },
                                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                                      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
            // Back text (always English)
            TextFormField(
              controller: _backTextController,
              decoration: const InputDecoration(
                labelText: 'Back Text (English)',
                hintText: 'Enter the translation or definition',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.translate),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter back text';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Category
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g., Vocabulary, Phrases, Grammar',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (Optional)',
                hintText: 'Separate tags with commas',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }
}
