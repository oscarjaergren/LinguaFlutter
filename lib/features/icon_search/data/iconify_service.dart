import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lingua_flutter/shared/domain/models/icon_model.dart';
import '../../../utils/constants.dart';

class IconifyService {
  final http.Client _client;

  IconifyService({http.Client? client}) : _client = client ?? http.Client();

  /// Search for icons using the Iconify API
  Future<List<IconModel>> searchIcons(String query, {int? limit}) async {
    if (query.trim().isEmpty) return [];

    try {
      final searchLimit = limit ?? AppConstants.defaultSearchLimit;
      final uri = Uri.parse('${AppConstants.iconifyBaseUrl}/search?query=${Uri.encodeComponent(query)}&limit=$searchLimit');
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final icons = data['icons'] as List<dynamic>?;
        final collections = data['collections'] as Map<String, dynamic>?;

        if (icons == null) return [];

        return icons
            .cast<String>()
            .map((iconId) {
              // Extract collection info if available
              final parts = iconId.split(':');
              final collectionId = parts.length > 1 ? parts[0] : null;
              final collectionName = collectionId != null
                  ? collections?[collectionId]?['name'] as String?
                  : null;

              return IconModel.fromIconify(
                iconId: iconId,
                collectionName: collectionName,
              );
            })
            .toList();
      } else {
        throw Exception('Failed to search icons: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching icons: $e');
    }
  }

  /// Get available icon collections
  Future<Map<String, dynamic>> getCollections() async {
    try {
      final uri = Uri.parse('${AppConstants.iconifyBaseUrl}/collections');
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get collections: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting collections: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
