import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/icon_provider.dart';
import '../widgets/iconify_icon.dart';
import '../models/icon_model.dart';

/// Screen for searching and selecting icons
class IconSearchScreen extends StatefulWidget {
  const IconSearchScreen({super.key});
  
  @override
  State<IconSearchScreen> createState() => _IconSearchScreenState();
}

class _IconSearchScreenState extends State<IconSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    // Load popular icons when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IconProvider>().loadPopularCollections();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  void _onSearchChanged(String query) {
    // Debounce the search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text == query) {
        context.read<IconProvider>().searchIcons(query);
      }
    });
  }
  
  void _onIconSelected(IconModel icon) {
    final provider = context.read<IconProvider>();
    provider.selectIcon(icon);
    
    // Show a snackbar to confirm selection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected "${icon.name}" icon'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Clear',
          onPressed: () => provider.clearSelection(),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Icons'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              hintText: 'Search for icons...',
              leading: const Icon(Icons.search),
              onChanged: _onSearchChanged,
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<IconProvider>().clearSearch();
                    },
                  ),
              ],
            ),
          ),
          
          // Selected icon display
          Consumer<IconProvider>(
            builder: (context, provider, child) {
              if (provider.selectedIcon != null) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconifyIcon(
                        icon: provider.selectedIcon!,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected: ${provider.selectedIcon!.name}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              'Set: ${provider.selectedIcon!.set}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => provider.clearSelection(),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Search results
          Expanded(
            child: Consumer<IconProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
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
                          'Error loading icons',
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
                          onPressed: () {
                            if (provider.searchQuery.isNotEmpty) {
                              provider.searchIcons(provider.searchQuery);
                            } else {
                              provider.loadPopularCollections();
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (provider.searchResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.searchQuery.isEmpty 
                              ? 'Search for icons above'
                              : 'No icons found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.searchQuery.isEmpty
                              ? 'Try searching for "home", "user", or "heart"'
                              : 'Try a different search term',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final icon = provider.searchResults[index];
                    final isSelected = provider.selectedIcon?.id == icon.id;
                    
                    return IconGridItem(
                      icon: icon,
                      isSelected: isSelected,
                      onTap: () => _onIconSelected(icon),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
