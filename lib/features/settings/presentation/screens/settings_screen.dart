import 'package:flutter/material.dart';
import '../../../../shared/widgets/ai_config_widget.dart';

/// Settings screen for app configuration
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AI Configuration Section
          Text(
            'AI Configuration',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Reusable AI config widget
          const AiConfigWidget(),
          const SizedBox(height: 24),

          // Status Card
          const AiConfigStatusCard(),
          const SizedBox(height: 24),

          // Help Section
          ExpansionTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('How to get an API key'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHelpStep(
                      context,
                      '1',
                      'Go to Google AI Studio',
                      'Visit aistudio.google.com',
                    ),
                    _buildHelpStep(
                      context,
                      '2',
                      'Sign in with Google',
                      'Use your Google account to sign in',
                    ),
                    _buildHelpStep(
                      context,
                      '3',
                      'Create API Key',
                      'Click "Get API key" and create a new key',
                    ),
                    _buildHelpStep(
                      context,
                      '4',
                      'Copy and paste',
                      'Copy the key and paste it above',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(
    BuildContext context,
    String number,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
