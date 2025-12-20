import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/features/language/domain/language_provider.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_provider.dart';
import 'package:lingua_flutter/features/card_management/data/repositories/card_management_repository.dart';

@GenerateMocks([CardManagementRepository])
import 'card_deletion_test.mocks.dart';

void main() {
  group('Card Deletion Tests', () {
    late CardManagementProvider provider;
    late MockCardManagementRepository mockRepository;
    late LanguageProvider languageProvider;
    late List<CardModel> testCards;

    setUp(() {
      mockRepository = MockCardManagementRepository();
      languageProvider = LanguageProvider();
      
      // Create test cards
      testCards = [
        CardModel.create(
          frontText: 'Card 1',
          backText: 'Translation 1',
          language: 'de',
          category: 'Test',
        ),
        CardModel.create(
          frontText: 'Card 2',
          backText: 'Translation 2',
          language: 'de',
          category: 'Test',
        ),
        CardModel.create(
          frontText: 'Card 3',
          backText: 'Translation 3',
          language: 'de',
          category: 'Test',
        ),
      ];
      
      provider = CardManagementProvider(
        languageProvider: languageProvider,
        repository: mockRepository,
      );
      
      // Default stubs
      when(mockRepository.getCategories()).thenAnswer((_) async => <String>[]);
      when(mockRepository.getTags()).thenAnswer((_) async => <String>[]);
    });

    tearDown(() {
      provider.dispose();
    });

    test('should delete one card and decrease card list count', () async {
      // Arrange
      when(mockRepository.getAllCards()).thenAnswer((_) async => testCards);
      await provider.loadCards();
      expect(provider.allCards.length, 3);
      
      final cardToDelete = provider.allCards.first;
      final remainingCards = testCards.where((c) => c.id != cardToDelete.id).toList();
      
      // Setup mock to return remaining cards after deletion
      when(mockRepository.deleteCard(cardToDelete.id)).thenAnswer((_) async {});
      when(mockRepository.getAllCards()).thenAnswer((_) async => remainingCards);
      
      // Act
      await provider.deleteCard(cardToDelete.id);
      
      // Assert
      verify(mockRepository.deleteCard(cardToDelete.id)).called(1);
      expect(provider.allCards.length, 2);
      expect(provider.allCards.any((c) => c.id == cardToDelete.id), false);
    });

    test('should delete two cards sequentially and update list correctly', () async {
      // Arrange
      when(mockRepository.getAllCards()).thenAnswer((_) async => testCards);
      await provider.loadCards();
      expect(provider.allCards.length, 3);
      
      final firstCardToDelete = provider.allCards[0];
      final secondCardToDelete = provider.allCards[1];
      
      // Setup mock for first deletion
      final afterFirstDelete = testCards.where((c) => c.id != firstCardToDelete.id).toList();
      when(mockRepository.deleteCard(firstCardToDelete.id)).thenAnswer((_) async {});
      when(mockRepository.getAllCards()).thenAnswer((_) async => afterFirstDelete);
      
      // Act - First deletion
      await provider.deleteCard(firstCardToDelete.id);
      
      // Assert after first deletion
      expect(provider.allCards.length, 2);
      expect(provider.allCards.any((c) => c.id == firstCardToDelete.id), false);
      
      // Setup mock for second deletion
      final afterSecondDelete = afterFirstDelete.where((c) => c.id != secondCardToDelete.id).toList();
      when(mockRepository.deleteCard(secondCardToDelete.id)).thenAnswer((_) async {});
      when(mockRepository.getAllCards()).thenAnswer((_) async => afterSecondDelete);
      
      // Act - Second deletion
      await provider.deleteCard(secondCardToDelete.id);
      
      // Assert after second deletion
      expect(provider.allCards.length, 1);
      expect(provider.allCards.any((c) => c.id == secondCardToDelete.id), false);
      expect(provider.allCards.first.frontText, 'Card 3');
    });

    test('should handle deletion of all cards', () async {
      // Arrange
      when(mockRepository.getAllCards()).thenAnswer((_) async => testCards);
      await provider.loadCards();
      expect(provider.allCards.length, 3);
      
      // Delete all cards one by one
      for (var i = 0; i < 3; i++) {
        final cardToDelete = provider.allCards.first;
        final remaining = provider.allCards.where((c) => c.id != cardToDelete.id).toList();
        
        when(mockRepository.deleteCard(cardToDelete.id)).thenAnswer((_) async {});
        when(mockRepository.getAllCards()).thenAnswer((_) async => remaining);
        
        await provider.deleteCard(cardToDelete.id);
      }
      
      // Assert
      expect(provider.allCards.length, 0);
      expect(provider.filteredCards.length, 0);
    });

    test('should update filtered cards after deletion', () async {
      // Arrange
      when(mockRepository.getAllCards()).thenAnswer((_) async => testCards);
      await provider.loadCards();
      
      // Apply a filter
      provider.searchCards('Card 1');
      expect(provider.filteredCards.length, 1);
      
      final cardToDelete = provider.filteredCards.first;
      when(mockRepository.deleteCard(cardToDelete.id)).thenAnswer((_) async {});
      when(mockRepository.getAllCards()).thenAnswer((_) async => 
        testCards.where((c) => c.id != cardToDelete.id).toList()
      );
      
      // Act
      await provider.deleteCard(cardToDelete.id);
      
      // Assert - filtered list should be empty now
      expect(provider.filteredCards.length, 0);
    });

    test('should notify listeners when card is deleted', () async {
      // Arrange
      when(mockRepository.getAllCards()).thenAnswer((_) async => testCards);
      await provider.loadCards();
      
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);
      
      final cardToDelete = provider.allCards.first;
      when(mockRepository.deleteCard(cardToDelete.id)).thenAnswer((_) async {});
      when(mockRepository.getAllCards()).thenAnswer((_) async => 
        testCards.where((c) => c.id != cardToDelete.id).toList()
      );
      
      // Act
      await provider.deleteCard(cardToDelete.id);
      
      // Assert - should notify at least once (immediate removal + after reload)
      expect(notifyCount, greaterThan(0));
    });

    test('should handle deletion error gracefully', () async {
      // Arrange
      when(mockRepository.getAllCards()).thenAnswer((_) async => testCards);
      await provider.loadCards();
      
      final cardToDelete = provider.allCards.first;
      when(mockRepository.deleteCard(cardToDelete.id))
          .thenThrow(Exception('Network error'));
      
      // Act & Assert
      expect(
        () => provider.deleteCard(cardToDelete.id),
        throwsException,
      );
      
      // Card should be removed from local state even if backend fails
      expect(provider.allCards.any((c) => c.id == cardToDelete.id), false);
    });
  });
}
