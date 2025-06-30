import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/icon_model.dart';

class IconifyService {
  static const String _baseUrl = 'https://api.iconify.design';
  final http.Client _client;

  IconifyService({http.Client? client}) : _client = client ?? http.Client();

  /// Search for icons using the Iconify API
  Future<List<IconModel>> searchIcons(String query, {int limit = 999}) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/search?query=${Uri.encodeComponent(query)}&limit=$limit');
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
              final collectionKey = parts.length > 1 ? parts[0] : null;
              final collectionInfo = collections?[collectionKey] as Map<String, dynamic>?;
              
              return IconModel.fromIconify(
                iconId: iconId,
                collectionName: collectionInfo?['name'] ?? collectionKey,
                tags: (collectionInfo?['tags'] as List<dynamic>?)
                    ?.cast<String>() ?? [],
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

  /// Get icon collections
  Future<Map<String, dynamic>> getCollections() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/collections'));
      
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
