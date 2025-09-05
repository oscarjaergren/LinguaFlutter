import 'package:flutter/material.dart';

/// Widget for search functionality in the card list
class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClosed;
  final String initialQuery;

  const SearchBarWidget({
    super.key,
    required this.onSearchChanged,
    required this.onSearchClosed,
    this.initialQuery = '',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();
    
    // Auto-focus when the search bar appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Search cards...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged('');
                  },
                  icon: const Icon(Icons.clear),
                ),
              IconButton(
                onPressed: widget.onSearchClosed,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        onChanged: widget.onSearchChanged,
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
