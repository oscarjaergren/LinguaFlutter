import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../providers/card_provider.dart';
import '../providers/streak_provider.dart';
import '../widgets/iconify_icon.dart';
import '../widgets/streak_status_widget.dart';
import 'simple_card_creation_screen.dart';
import 'card_review_screen.dart';

/// Screen for displaying and managing the list of cards
class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardProvider>().initialize();
      context.read<StreakProvider>().loadStreak();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'All'),
            Tab(icon: Icon(Icons.schedule), text: 'Due'),
            Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
            Tab(icon: Icon(Icons.archive), text: 'Archived'),
          ],
        ),
        actions: [
          Consumer<CardProvider>(
            builder: (context, provider, child) {
              if (provider.reviewCards.isNotEmpty) {
                return TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CardReviewScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Review (${provider.reviewCards.length})'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Streak status
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: StreakStatusWidget(compact: true),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search cards...',
              leading: const Icon(Icons.search),
              onChanged: (query) {
                context.read<CardProvider>().searchCards(query);
              },
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<CardProvider>().clearFilters();
                    },
                  ),
              ],
            ),
          ),
          
          // Filters row
          Consumer<CardProvider>(
            builder: (context, provider, child) {
              if (provider.categories.isNotEmpty) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Categories'),
                        selected: provider.selectedCategory.isEmpty,
                        onSelected: (selected) {
                          if (selected) {
                            provider.filterByCategory('');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ...provider.categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(category),
                            selected: provider.selectedCategory == category,
                            onSelected: (selected) {
                              provider.filterByCategory(selected ? category : '');
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          const SizedBox(height: 8),
          
          // Statistics bar
          Consumer<CardProvider>(
            builder: (context, provider, child) {
              final stats = provider.stats;
              if (stats.isEmpty) return const SizedBox.shrink();
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.dashboard,
                      label: 'Total',
                      value: stats['total'] ?? 0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    _StatItem(
                      icon: Icons.schedule,
                      label: 'Due',
                      value: stats['due'] ?? 0,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    _StatItem(
                      icon: Icons.star,
                      label: 'Mastered',
                      value: stats['mastered'] ?? 0,
                      color: Colors.green,
                    ),
                    _StatItem(
                      icon: Icons.favorite,
                      label: 'Favorites',
                      value: stats['favorites'] ?? 0,
                      color: Colors.pink,
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Card list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CardListView(CardListType.all),
                _CardListView(CardListType.due),
                _CardListView(CardListType.favorites),
                _CardListView(CardListType.archived),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SimpleCardCreationScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum CardListType { all, due, favorites, archived }

class _CardListView extends StatelessWidget {
  final CardListType type;
  
  const _CardListView(this.type);

  @override
  Widget build(BuildContext context) {
    return Consumer<CardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (provider.errorMessage != null) {
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
                  'Error loading cards',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => provider.initialize(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        List<CardModel> cards;
        switch (type) {
          case CardListType.all:
            cards = provider.filteredCards.where((card) => !card.isArchived).toList();
            break;
          case CardListType.due:
            cards = provider.reviewCards;
            break;
          case CardListType.favorites:
            cards = provider.filteredCards.where((card) => card.isFavorite && !card.isArchived).toList();
            break;
          case CardListType.archived:
            cards = provider.filteredCards.where((card) => card.isArchived).toList();
            break;
        }
        
        if (cards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getEmptyIcon(),
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptySubtitle(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (type == CardListType.all)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SimpleCardCreationScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Card'),
                  ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return _CardListItem(card: card);
          },
        );
      },
    );
  }
  
  IconData _getEmptyIcon() {
    switch (type) {
      case CardListType.all: return Icons.quiz;
      case CardListType.due: return Icons.schedule;
      case CardListType.favorites: return Icons.favorite_border;
      case CardListType.archived: return Icons.archive;
    }
  }
  
  String _getEmptyMessage() {
    switch (type) {
      case CardListType.all: return 'No cards yet';
      case CardListType.due: return 'No cards due';
      case CardListType.favorites: return 'No favorites';
      case CardListType.archived: return 'No archived cards';
    }
  }
  
  String _getEmptySubtitle() {
    switch (type) {
      case CardListType.all: return 'Create your first card to start learning';
      case CardListType.due: return 'All caught up! Great job!';
      case CardListType.favorites: return 'Favorite cards will appear here';
      case CardListType.archived: return 'Archived cards will appear here';
    }
  }
}

class _CardListItem extends StatelessWidget {
  final CardModel card;
  
  const _CardListItem({required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: card.icon != null
            ? CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: IconifyIcon(
                  icon: card.icon!,
                  size: 24,
                ),
              )
            : CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(
                  card.frontText.isNotEmpty ? card.frontText[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        title: Text(
          card.germanArticle != null 
              ? '${card.germanArticle} ${card.frontText}'
              : card.frontText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.backText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _StatusChip(
                  label: card.masteryLevel,
                  color: _getMasteryColor(context, card.masteryLevel),
                ),
                const SizedBox(width: 8),
                if (card.isDueForReview) ...[
                  _StatusChip(
                    label: 'Due',
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                ],
                if (card.isFavorite) ...[
                  Icon(
                    Icons.favorite,
                    size: 16,
                    color: Colors.pink,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  card.category,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            final provider = context.read<CardProvider>();
            switch (action) {
              case 'edit':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SimpleCardCreationScreen(cardToEdit: card),
                  ),
                );
                break;
              case 'favorite':
                await provider.toggleFavorite(card.id);
                break;
              case 'archive':
                await provider.toggleArchive(card.id);
                break;
              case 'delete':
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Card'),
                    content: Text('Are you sure you want to delete "${card.germanArticle != null ? '${card.germanArticle} ${card.frontText}' : card.frontText}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await provider.deleteCard(card.id);
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'favorite',
              child: ListTile(
                leading: Icon(card.isFavorite ? Icons.favorite : Icons.favorite_border),
                title: Text(card.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'archive',
              child: ListTile(
                leading: Icon(card.isArchived ? Icons.unarchive : Icons.archive),
                title: Text(card.isArchived ? 'Unarchive' : 'Archive'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                dense: true,
              ),
            ),
          ],
        ),
        onTap: () {
          // Quick review single card
          context.read<CardProvider>().startReviewSession(cards: [card]);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CardReviewScreen(),
            ),
          );
        },
      ),
    );
  }
  
  Color _getMasteryColor(BuildContext context, String mastery) {
    switch (mastery) {
      case 'New': return Theme.of(context).colorScheme.primary;
      case 'Learning': return Colors.orange;  
      case 'Good': return Colors.blue;
      case 'Mastered': return Colors.green;
      case 'Difficult': return Colors.red;
      default: return Theme.of(context).colorScheme.onSurface;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
