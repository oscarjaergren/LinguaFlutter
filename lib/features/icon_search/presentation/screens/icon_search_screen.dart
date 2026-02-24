import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_flutter/features/icon_search/domain/icon_notifier.dart';
import 'package:lingua_flutter/features/icon_search/presentation/widgets/icon_grid_item.dart';
import 'package:lingua_flutter/features/icon_search/presentation/widgets/iconify_icon.dart';
import 'package:lingua_flutter/shared/domain/models/icon_model.dart';

/// Screen for searching and selecting icons
class IconSearchScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;

  const IconSearchScreen({super.key, this.initialSearchQuery});

  @override
  ConsumerState<IconSearchScreen> createState() => _IconSearchScreenState();
}

class _IconSearchScreenState extends ConsumerState<IconSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Initialize search controller with initial query if provided
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!.trim();
    }

    // Load content when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialSearchQuery != null &&
          widget.initialSearchQuery!.trim().isNotEmpty) {
        // Auto-search with the initial query
        ref
            .read(iconNotifierProvider.notifier)
            .searchIcons(widget.initialSearchQuery!.trim());
      } else {
        // Load popular icons when no initial query
        ref.read(iconNotifierProvider.notifier).loadPopularCollections();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel the previous timer
    _debounceTimer?.cancel();

    // Start a new timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(iconNotifierProvider.notifier).searchIcons(query);
      }
    });
  }

  void _onIconSelected(IconModel icon) {
    ref.read(iconNotifierProvider.notifier).selectIcon(icon);

    // Automatically close the screen and return the selected icon
    Navigator.of(context).pop(icon);
  }

  /// Calculate the number of columns based on screen width
  int _calculateCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = 60.0; // Approximate width for each icon item
    final padding = 32.0; // Total horizontal padding
    final spacing = 4.0; // Spacing between items

    // Calculate how many items can fit
    final availableWidth = screenWidth - padding;
    final crossAxisCount = ((availableWidth + spacing) / (itemWidth + spacing))
        .floor();

    // Ensure we have at least 3 columns and at most 12
    return crossAxisCount.clamp(3, 12);
  }

  @override
  Widget build(BuildContext context) {
    final iconState = ref.watch(iconNotifierProvider);
    final iconNotifier = ref.read(iconNotifierProvider.notifier);

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
                      iconNotifier.clearSearch();
                    },
                  ),
              ],
            ),
          ),

          // Selected icon display
          if (iconState.selectedIcon != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconifyIcon(icon: iconState.selectedIcon!, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected: ${iconState.selectedIcon!.name}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Set: ${iconState.selectedIcon!.set}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => iconNotifier.clearSelection(),
                  ),
                ],
              ),
            ),

          // Results counter
          if (iconState.searchResults.isNotEmpty && !iconState.isLoading)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${iconState.searchResults.length} icons found',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (iconState.searchQuery.isNotEmpty) ...[
                    const Spacer(),
                    Text(
                      'for "${iconState.searchQuery}"',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Search results
          Expanded(
            child: Builder(
              builder: (context) {
                if (iconState.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (iconState.errorMessage != null) {
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
                          iconState.errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            if (iconState.searchQuery.isNotEmpty) {
                              iconNotifier.searchIcons(iconState.searchQuery);
                            } else {
                              iconNotifier.loadPopularCollections();
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (iconState.searchResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          iconState.searchQuery.isEmpty
                              ? 'Search for icons above'
                              : 'No icons found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          iconState.searchQuery.isEmpty
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
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _calculateCrossAxisCount(context),
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: iconState.searchResults.length,
                  cacheExtent: 200,
                  itemBuilder: (context, index) {
                    final icon = iconState.searchResults[index];
                    final isSelected = iconState.selectedIcon?.id == icon.id;

                    return Tooltip(
                      message: '${icon.name}\n${icon.set}',
                      child: IconGridItem(
                        icon: icon,
                        isSelected: isSelected,
                        onTap: () => _onIconSelected(icon),
                      ),
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
