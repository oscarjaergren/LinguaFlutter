import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:lingua_flutter/services/iconify_service.dart';

void main() {
  group('IconifyService', () {
    test('should search icons successfully', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('search?query=home'));
        
        final responseBody = json.encode({
          'icons': ['mdi:home', 'lucide:home', 'heroicons:home'],
          'collections': {
            'mdi': {'name': 'Material Design Icons'},
            'lucide': {'name': 'Lucide'},
            'heroicons': {'name': 'Heroicons'},
          },
        });
        
        return http.Response(responseBody, 200);
      });

      final service = IconifyService(client: mockClient);
      final results = await service.searchIcons('home');

      expect(results, hasLength(3));
      expect(results[0].id, 'mdi:home');
      expect(results[0].name, 'home');
      expect(results[0].set, 'mdi');
      expect(results[0].category, 'Material Design Icons');
      expect(results[0].svgUrl, 'https://api.iconify.design/mdi:home.svg');
    });

    test('should handle empty search query', () async {
      final service = IconifyService();
      final results = await service.searchIcons('');

      expect(results, isEmpty);
    });

    test('should handle whitespace-only search query', () async {
      final service = IconifyService();
      final results = await service.searchIcons('   ');

      expect(results, isEmpty);
    });

    test('should handle API error response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = IconifyService(client: mockClient);

      expect(
        () => service.searchIcons('home'),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle malformed JSON response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('invalid json', 200);
      });

      final service = IconifyService(client: mockClient);

      expect(
        () => service.searchIcons('home'),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle response with no icons', () async {
      final mockClient = MockClient((request) async {
        final responseBody = json.encode({
          'icons': null,
          'collections': {},
        });
        
        return http.Response(responseBody, 200);
      });

      final service = IconifyService(client: mockClient);
      final results = await service.searchIcons('nonexistent');

      expect(results, isEmpty);
    });

    test('should handle response with empty icons array', () async {
      final mockClient = MockClient((request) async {
        final responseBody = json.encode({
          'icons': [],
          'collections': {},
        });
        
        return http.Response(responseBody, 200);
      });

      final service = IconifyService(client: mockClient);
      final results = await service.searchIcons('nonexistent');

      expect(results, isEmpty);
    });

    test('should respect search limit parameter', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('limit=10'));
        
        final responseBody = json.encode({
          'icons': ['mdi:home'],
          'collections': {'mdi': {'name': 'Material Design Icons'}},
        });
        
        return http.Response(responseBody, 200);
      });

      final service = IconifyService(client: mockClient);
      await service.searchIcons('home', limit: 10);
    });

    test('should URL encode search query', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('query=hello%20world'));
        
        final responseBody = json.encode({
          'icons': [],
          'collections': {},
        });
        
        return http.Response(responseBody, 200);
      });

      final service = IconifyService(client: mockClient);
      await service.searchIcons('hello world');
    });

    test('should get collections successfully', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('collections'));
        
        final responseBody = json.encode({
          'mdi': {
            'name': 'Material Design Icons',
            'total': 7447,
            'author': {'name': 'Austin Andrews'},
            'license': {'title': 'Apache 2.0'},
          },
          'lucide': {
            'name': 'Lucide',
            'total': 1458,
            'author': {'name': 'Lucide Contributors'},
            'license': {'title': 'ISC'},
          },
        });
        
        return http.Response(responseBody, 200);
      });

      final service = IconifyService(client: mockClient);
      final collections = await service.getCollections();

      expect(collections, isNotEmpty);
      expect(collections['mdi']?['name'], 'Material Design Icons');
      expect(collections['lucide']?['name'], 'Lucide');
    });

    test('should handle collections API error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = IconifyService(client: mockClient);

      expect(
        () => service.getCollections(),
        throwsA(isA<Exception>()),
      );
    });

    test('should dispose client properly', () {
      final service = IconifyService();
      // Should not throw
      service.dispose();
    });
  });
}
