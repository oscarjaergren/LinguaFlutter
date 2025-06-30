import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../models/icon_model.dart';
import '../providers/card_provider.dart';
import '../providers/icon_provider.dart';
import '../widgets/iconify_icon.dart';
import 'icon_search_screen.dart';

/// Screen for creating and editing language learning cards
class CardCreationScreen extends StatefulWidget {
  final CardModel? cardToEdit;
  
  const CardCreationScreen({
    super.key,
    this.cardToEdit,
  });

  @override
  State<CardCreationScreen> createState() => _CardCreationScreenState();
}

class _CardCreationScreenState extends State<CardCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _frontTextController = TextEditingController();
  final _backTextController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String _frontLanguage = 'en';
  String _backLanguage = 'es';
  int _difficulty = 1;
  IconModel? _selectedIcon;
  bool _isLoading = false;
  
  final List<String> _commonLanguages = [
    'en', 'es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ko', 'ru', 'ar'
  ];
  
  final List<String> _languageNames = [
    'English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese', 
    'Chinese', 'Japanese', 'Korean', 'Russian', 'Arabic'
  ];

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
      _frontLanguage = card.frontLanguage;
      _backLanguage = card.backLanguage;
      _difficulty = card.difficulty;
      _selectedIcon = card.icon;
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
    
    // Navigate to icon search screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IconSearchScreen(),
      ),
    );
    
    // Get the selected icon after returning
    final selectedIcon = context.read<IconProvider>().selectedIcon;
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
          frontLanguage: _frontLanguage,
          backLanguage: _backLanguage,
          category: _categoryController.text.trim(),
          tags: tags,
          difficulty: _difficulty,
          updatedAt: DateTime.now(),
        );
        
        await cardProvider.updateCard(updatedCard);
      } else {
        // Create new card
        final newCard = CardModel.create(
          frontText: _frontTextController.text.trim(),
          backText: _backTextController.text.trim(),
          icon: _selectedIcon,
          frontLanguage: _frontLanguage,
          backLanguage: _backLanguage,
          category: _categoryController.text.trim(),
          tags: tags,
          difficulty: _difficulty,
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
            TextFormField(
              controller: _frontTextController,
              decoration: InputDecoration(
                labelText: 'Front Text (${_languageNames[_commonLanguages.indexOf(_frontLanguage)]})',
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
            ),
            
            const SizedBox(height: 16),
            
            // Back text
            TextFormField(
              controller: _backTextController,
              decoration: InputDecoration(
                labelText: 'Back Text (${_languageNames[_commonLanguages.indexOf(_backLanguage)]})',
                hintText: 'Enter the translation or definition',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.translate),
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
            
            // Language selection
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _frontLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Front Language',
                      border: OutlineInputBorder(),
                    ),
                    items: _commonLanguages.map((lang) {
                      final index = _commonLanguages.indexOf(lang);
                      return DropdownMenuItem(
                        value: lang,
                        child: Text('${_languageNames[index]} ($lang)'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _frontLanguage = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _backLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Back Language',
                      border: OutlineInputBorder(),
                    ),
                    items: _commonLanguages.map((lang) {
                      final index = _commonLanguages.indexOf(lang);
                      return DropdownMenuItem(
                        value: lang,
                        child: Text('${_languageNames[index]} ($lang)'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _backLanguage = value!;
                      });
                    },
                  ),
                ),
              ],
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
              textInputAction: TextInputAction.next,
            ),
            
            const SizedBox(height: 16),
            
            // Difficulty
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Difficulty Level: $_difficulty',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _difficulty.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _getDifficultyLabel(_difficulty),
                      onChanged: (value) {
                        setState(() {
                          _difficulty = value.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Easy',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Hard',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Preview card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (_selectedIcon != null) ...[
                            IconifyIcon(
                              icon: _selectedIcon!,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            _frontTextController.text.isNotEmpty 
                                ? _frontTextController.text 
                                : 'Front text will appear here',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            _backTextController.text.isNotEmpty 
                                ? _backTextController.text 
                                : 'Back text will appear here',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1: return 'Very Easy';
      case 2: return 'Easy';
      case 3: return 'Medium';
      case 4: return 'Hard';
      case 5: return 'Very Hard';
      default: return 'Medium';
    }
  }
}
