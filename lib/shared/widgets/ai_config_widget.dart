import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/card_management/domain/providers/card_enrichment_notifier.dart';
import '../services/ai/ai.dart';

/// Reusable widget for configuring AI provider and API key
class AiConfigWidget extends ConsumerStatefulWidget {
  /// Called after successful save
  final VoidCallback? onSaved;

  /// Whether to show as a dialog (compact) or full form
  final bool compact;

  const AiConfigWidget({super.key, this.onSaved, this.compact = false});

  @override
  ConsumerState<AiConfigWidget> createState() => _AiConfigWidgetState();
}

class _AiConfigWidgetState extends ConsumerState<AiConfigWidget> {
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _isTestingKey = false;
  late AiProvider _selectedProvider;
  late String _selectedModel;

  @override
  void initState() {
    super.initState();
    final config = ref.read(cardEnrichmentNotifierProvider).config;
    _apiKeyController.text = config.apiKey ?? '';
    _selectedProvider = config.provider;
    _selectedModel = config.model ?? _selectedProvider.defaultModel;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final notifier = ref.read(cardEnrichmentNotifierProvider.notifier);
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      await notifier.setApiKey(null);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('API key cleared')));
      }
      return;
    }

    await notifier.setProvider(_selectedProvider);
    await notifier.setModel(_selectedModel);
    await notifier.setApiKey(apiKey);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI configuration saved')));
      widget.onSaved?.call();
    }
  }

  Future<void> _testApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API key first')),
      );
      return;
    }

    setState(() => _isTestingKey = true);

    try {
      final service = AiService();
      final testConfig = AiConfig(
        apiKey: apiKey,
        provider: _selectedProvider,
        model: _selectedModel,
      );

      await service.complete(
        prompt: 'Say "Hello" in one word.',
        config: testConfig,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key is valid!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API key test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingKey = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.compact) ...[
          Text(
            'Select a provider and enter your API key.\n'
            'Gemini offers a free tier - get a key at ai.google.dev',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Provider dropdown
        DropdownButtonFormField<AiProvider>(
          value: _selectedProvider,
          decoration: const InputDecoration(
            labelText: 'Provider',
            border: OutlineInputBorder(),
          ),
          items: AiProvider.values
              .map(
                (p) => DropdownMenuItem(value: p, child: Text(p.displayName)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedProvider = value;
                _selectedModel = value.defaultModel;
              });
            }
          },
        ),
        const SizedBox(height: 16),

        // Model dropdown
        DropdownButtonFormField<String>(
          value: _selectedModel,
          decoration: const InputDecoration(
            labelText: 'Model',
            border: OutlineInputBorder(),
          ),
          items: _selectedProvider.availableModels
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(m, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedModel = value);
            }
          },
        ),
        const SizedBox(height: 16),

        // API Key input
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureApiKey,
          decoration: InputDecoration(
            labelText: 'API Key',
            hintText: _selectedProvider == AiProvider.gemini
                ? 'AIza...'
                : 'sk-...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.key),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureApiKey = !_obscureApiKey);
                  },
                  tooltip: _obscureApiKey ? 'Show key' : 'Hide key',
                ),
                if (_apiKeyController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _apiKeyController.clear();
                      setState(() {});
                    },
                    tooltip: 'Clear',
                  ),
              ],
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isTestingKey ? null : _testApiKey,
                icon: _isTestingKey
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.science),
                label: const Text('Test'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _saveConfig,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shows a dialog for AI configuration
Future<void> showAiConfigDialog(BuildContext context, {VoidCallback? onSaved}) {
  return showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('AI Configuration'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 300,
          child: AiConfigWidget(
            compact: true,
            onSaved: () {
              Navigator.pop(dialogContext);
              onSaved?.call();
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

/// Status card showing current AI configuration state
class AiConfigStatusCard extends ConsumerWidget {
  const AiConfigStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(cardEnrichmentNotifierProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              state.isConfigured ? Icons.check_circle : Icons.warning,
              color: state.isConfigured ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.isConfigured
                        ? 'AI Enrichment Enabled'
                        : 'AI Not Configured',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    state.isConfigured
                        ? '${state.config.provider.displayName} - ${state.config.effectiveModel}'
                        : 'Add your API key to enable word enrichment',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
