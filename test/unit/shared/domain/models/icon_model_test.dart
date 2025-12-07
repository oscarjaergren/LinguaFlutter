import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/icon_model.dart';

void main() {
  group('IconModel', () {
    test('should create IconModel from JSON', () {
      final json = {
        'id': 'mdi:home',
        'name': 'Home',
        'set': 'mdi',
        'category': 'Actions',
        'tags': ['house', 'building'],
        'svgUrl': 'https://api.iconify.design/mdi:home.svg',
      };

      final icon = IconModel.fromJson(json);

      expect(icon.id, 'mdi:home');
      expect(icon.name, 'Home');
      expect(icon.set, 'mdi');
      expect(icon.category, 'Actions');
      expect(icon.tags, ['house', 'building']);
      expect(icon.svgUrl, 'https://api.iconify.design/mdi:home.svg');
    });

    test('should convert IconModel to JSON', () {
      const icon = IconModel(
        id: 'mdi:heart',
        name: 'Heart',
        set: 'mdi',
        category: 'Emotions',
        tags: ['love', 'like'],
        svgUrl: 'https://api.iconify.design/mdi:heart.svg',
      );

      final json = icon.toJson();

      expect(json['id'], 'mdi:heart');
      expect(json['name'], 'Heart');
      expect(json['set'], 'mdi');
      expect(json['category'], 'Emotions');
      expect(json['tags'], ['love', 'like']);
      expect(json['svgUrl'], 'https://api.iconify.design/mdi:heart.svg');
    });

    test('should create IconModel from Iconify response', () {
      const iconId = 'mdi:home';
      const collectionName = 'Material Design Icons';
      const tags = ['house', 'building'];

      final icon = IconModel.fromIconify(
        iconId: iconId,
        collectionName: collectionName,
        tags: tags,
      );

      expect(icon.id, 'mdi:home');
      expect(icon.name, 'home'); // Name should be formatted from ID
      expect(icon.set, 'mdi');
      expect(icon.category, 'Material Design Icons');
      expect(icon.tags, ['house', 'building']);
      expect(icon.svgUrl, 'https://api.iconify.design/mdi:home.svg');
    });

    test('should handle icon ID with hyphens and underscores in name', () {
      const iconId = 'mdi:account-plus_outline';

      final icon = IconModel.fromIconify(iconId: iconId);

      expect(icon.name, 'account plus outline'); // Should replace - and _ with spaces
    });

    test('should handle icon ID without collection prefix', () {
      const iconId = 'home';

      final icon = IconModel.fromIconify(iconId: iconId);

      expect(icon.id, 'home');
      expect(icon.name, 'home');
      expect(icon.set, 'unknown');
      expect(icon.category, 'Unknown');
    });

    test('should implement equality correctly', () {
      const icon1 = IconModel(
        id: 'mdi:home',
        name: 'Home',
        set: 'mdi',
        category: 'Actions',
        tags: ['house'],
        svgUrl: 'https://api.iconify.design/mdi:home.svg',
      );

      const icon2 = IconModel(
        id: 'mdi:home',
        name: 'Home Different Name', // Different name, same ID
        set: 'mdi',
        category: 'Actions',
        tags: ['house'],
        svgUrl: 'https://api.iconify.design/mdi:home.svg',
      );

      const icon3 = IconModel(
        id: 'mdi:heart',
        name: 'Heart',
        set: 'mdi',
        category: 'Emotions',
        tags: ['love'],
        svgUrl: 'https://api.iconify.design/mdi:heart.svg',
      );

      expect(icon1, equals(icon2)); // Same ID = equal
      expect(icon1, isNot(equals(icon3))); // Different ID = not equal
      expect(icon1.hashCode, equals(icon2.hashCode));
      expect(icon1.hashCode, isNot(equals(icon3.hashCode)));
    });
  });
}
