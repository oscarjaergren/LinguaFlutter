import 'package:flutter/material.dart';
import '../../../../shared/domain/models/exercise_type.dart';
import '../../domain/models/exercise_preferences.dart';

/// Bottom sheet for filtering exercise types during a practice session
class ExerciseFilterSheet extends StatefulWidget {
  final ExercisePreferences preferences;
  final ValueChanged<ExercisePreferences> onPreferencesChanged;

  const ExerciseFilterSheet({
    super.key,
    required this.preferences,
    required this.onPreferencesChanged,
  });

  /// Show the filter sheet as a modal bottom sheet
  static Future<ExercisePreferences?> show(
    BuildContext context, {
    required ExercisePreferences currentPreferences,
  }) async {
    return showModalBottomSheet<ExercisePreferences>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        ExercisePreferences prefs = currentPreferences;
        return StatefulBuilder(
          builder: (context, setState) {
            return ExerciseFilterSheet(
              preferences: prefs,
              onPreferencesChanged: (newPrefs) {
                setState(() => prefs = newPrefs);
              },
            );
          },
        );
      },
    ).then((result) => result);
  }

  @override
  State<ExerciseFilterSheet> createState() => _ExerciseFilterSheetState();
}

class _ExerciseFilterSheetState extends State<ExerciseFilterSheet> {
  late ExercisePreferences _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences;
  }

  void _updatePreferences(ExercisePreferences newPrefs) {
    setState(() {
      _preferences = newPrefs;
    });
    widget.onPreferencesChanged(newPrefs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercise Types',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_preferences.enabledCount} of ${ExerciseType.values.where((t) => t.isImplemented).length} enabled',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quick actions
                TextButton(
                  onPressed: () => _updatePreferences(_preferences.enableAll()),
                  child: const Text('All'),
                ),
                TextButton(
                  onPressed: () => _updatePreferences(_preferences.disableAll()),
                  child: const Text('None'),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Category toggles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildCategoryChip(
                    ExerciseCategory.recognition,
                    Icons.visibility,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryChip(
                    ExerciseCategory.production,
                    Icons.edit,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Exercise type list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final type in ExerciseType.values.where((t) => t.isImplemented))
                  _buildExerciseTypeTile(type),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Prioritize weaknesses toggle
          SwitchListTile(
            title: const Text('Prioritize Weaknesses'),
            subtitle: const Text('Focus on exercise types you struggle with'),
            value: _preferences.prioritizeWeaknesses,
            onChanged: (value) {
              _updatePreferences(_preferences.copyWith(prioritizeWeaknesses: value));
            },
          ),
          
          // Apply button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _preferences.hasAnyEnabled
                    ? () => Navigator.pop(context, _preferences)
                    : null,
                child: const Text('Apply'),
              ),
            ),
          ),
          
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(ExerciseCategory category, IconData icon) {
    final isFullyEnabled = _preferences.isCategoryFullyEnabled(category);
    final isPartiallyEnabled = _preferences.isCategoryPartiallyEnabled(category);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isFullyEnabled || isPartiallyEnabled
                ? colorScheme.onSecondaryContainer
                : colorScheme.outline,
          ),
          const SizedBox(width: 6),
          Text(category.displayName),
        ],
      ),
      selected: isFullyEnabled,
      showCheckmark: false,
      onSelected: (selected) {
        _updatePreferences(_preferences.toggleCategory(category, enabled: selected));
      },
      avatar: isPartiallyEnabled && !isFullyEnabled
          ? Icon(
              Icons.remove,
              size: 18,
              color: colorScheme.outline,
            )
          : null,
    );
  }

  Widget _buildExerciseTypeTile(ExerciseType type) {
    final isEnabled = _preferences.isEnabled(type);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          type.icon,
          size: 20,
          color: isEnabled
              ? colorScheme.onPrimaryContainer
              : colorScheme.outline,
        ),
      ),
      title: Text(type.displayName),
      subtitle: Text(
        type.description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.outline,
        ),
      ),
      trailing: Switch(
        value: isEnabled,
        onChanged: (_) => _updatePreferences(_preferences.toggleType(type)),
      ),
      onTap: () => _updatePreferences(_preferences.toggleType(type)),
    );
  }
}
