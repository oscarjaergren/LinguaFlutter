import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../language/language.dart';

/// Widget for selecting the active language in the app bar
class LanguageSelectorWidget extends ConsumerWidget {
  const LanguageSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageNotifierProvider);
    final languageNotifier = ref.read(languageNotifierProvider.notifier);

    final activeLanguage = languageState.activeLanguage;
    final languageDetails = languageNotifier.getLanguageDetails(
      activeLanguage,
    )!;

    return PopupMenuButton<String>(
      onSelected: (String languageCode) {
        languageNotifier.setActiveLanguage(languageCode);
        // CardManagementProvider listens to languageNotifierProvider automatically
      },
      itemBuilder: (BuildContext context) {
        return languageState.availableLanguages.entries.map((entry) {
          final code = entry.key;
          final details = entry.value;
          return PopupMenuItem<String>(
            value: code,
            child: Row(
              children: [
                Text(details['flag'], style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(details['name']),
                if (code == activeLanguage) ...[
                  const Spacer(),
                  Icon(
                    Icons.check,
                    color: languageNotifier.getLanguageColor(code),
                    size: 16,
                  ),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(languageDetails['flag'], style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            languageDetails['name'],
            style: TextStyle(
              color: languageNotifier.getLanguageColor(activeLanguage),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            color: languageNotifier.getLanguageColor(activeLanguage),
          ),
        ],
      ),
    );
  }
}
