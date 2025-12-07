import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/word_data.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_score.dart';
import 'package:lingua_flutter/features/auth/data/services/supabase_auth_service.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

/// Service for storing and retrieving cards from Supabase
class SupabaseCardService {
  static const String _tableName = 'cards';

  /// Get the Supabase client
  SupabaseClient get _client => SupabaseAuthService.client;

  /// Get current user ID or throw if not authenticated
  String get _userId {
    final userId = SupabaseAuthService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return userId;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => SupabaseAuthService.isAuthenticated;

  /// Load all cards for current user
  Future<List<CardModel>> loadCards({String? languageCode}) async {
    try {
      var query = _client
          .from(_tableName)
          .select()
          .eq('user_id', _userId);

      if (languageCode != null) {
        query = query.eq('language_code', languageCode);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => _cardFromSupabase(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      LoggerService.error('Failed to load cards from Supabase', e);
      rethrow;
    }
  }

  /// Save a single card (insert or update)
  Future<CardModel> saveCard(CardModel card) async {
    try {
      final data = _cardToSupabase(card);
      LoggerService.debug('Saving card to Supabase: $data');
      
      final response = await _client
          .from(_tableName)
          .upsert(data)
          .select()
          .single();

      LoggerService.debug('Card saved to Supabase: ${card.id}');
      return _cardFromSupabase(response);
    } on PostgrestException catch (e) {
      LoggerService.error('Supabase error saving card: ${e.message}', e);
      LoggerService.error('Error code: ${e.code}, details: ${e.details}');
      rethrow;
    } catch (e) {
      LoggerService.error('Failed to save card to Supabase', e);
      rethrow;
    }
  }

  /// Save multiple cards
  Future<void> saveCards(List<CardModel> cards) async {
    try {
      final data = cards.map(_cardToSupabase).toList();
      
      await _client
          .from(_tableName)
          .upsert(data);

      LoggerService.debug('Saved ${cards.length} cards to Supabase');
    } catch (e) {
      LoggerService.error('Failed to save cards to Supabase', e);
      rethrow;
    }
  }

  /// Delete a card by ID
  Future<void> deleteCard(String cardId) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq('id', cardId)
          .eq('user_id', _userId);

      LoggerService.debug('Card deleted from Supabase: $cardId');
    } catch (e) {
      LoggerService.error('Failed to delete card from Supabase', e);
      rethrow;
    }
  }

  /// Delete all cards for current user
  Future<void> clearAllCards() async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq('user_id', _userId);

      LoggerService.debug('All cards cleared from Supabase');
    } catch (e) {
      LoggerService.error('Failed to clear cards from Supabase', e);
      rethrow;
    }
  }

  /// Get cards due for review
  Future<List<CardModel>> getDueCards({String? languageCode}) async {
    try {
      var query = _client
          .from(_tableName)
          .select()
          .eq('user_id', _userId)
          .eq('is_archived', false)
          .lte('next_review', DateTime.now().toIso8601String());

      if (languageCode != null) {
        query = query.eq('language_code', languageCode);
      }

      final response = await query.order('next_review', ascending: true);

      return (response as List)
          .map((json) => _cardFromSupabase(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      LoggerService.error('Failed to get due cards from Supabase', e);
      rethrow;
    }
  }

  /// Get card count by language
  Future<Map<String, int>> getCardCountsByLanguage() async {
    try {
      final response = await _client
          .from(_tableName)
          .select('language_code')
          .eq('user_id', _userId)
          .eq('is_archived', false);

      final counts = <String, int>{};
      for (final row in response as List) {
        final lang = row['language_code'] as String;
        counts[lang] = (counts[lang] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      LoggerService.error('Failed to get card counts from Supabase', e);
      rethrow;
    }
  }

  /// Convert CardModel to Supabase row format
  Map<String, dynamic> _cardToSupabase(CardModel card) {
    return {
      'id': card.id,
      'user_id': _userId,
      'front_text': card.frontText,
      'back_text': card.backText,
      'language_code': card.language,
      'category': card.category,
      'tags': card.tags,
      'examples': card.examples,
      'notes': card.notes,
      'word_data': card.wordData?.toJson(),
      'next_review': card.nextReview?.toIso8601String(),
      'review_count': card.reviewCount,
      'correct_count': card.correctCount,
      'ease_factor': 2.5, // Default SM-2 ease factor
      'interval_days': _calculateIntervalDays(card),
      'is_archived': card.isArchived,
      'is_favorite': card.isFavorite,
      'created_at': card.createdAt.toIso8601String(),
      'updated_at': card.updatedAt.toIso8601String(),
    };
  }

  /// Convert Supabase row to CardModel
  CardModel _cardFromSupabase(Map<String, dynamic> json) {
    // Parse word_data if present
    WordData? wordData;
    if (json['word_data'] != null) {
      wordData = WordData.fromJson(json['word_data'] as Map<String, dynamic>);
    }

    // Parse tags
    final tags = (json['tags'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [];

    // Parse examples
    final examples = (json['examples'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [];

    return CardModel(
      id: json['id'] as String,
      frontText: json['front_text'] as String,
      backText: json['back_text'] as String,
      language: json['language_code'] as String? ?? 'de',
      category: json['category'] as String? ?? 'vocabulary',
      tags: tags,
      examples: examples,
      notes: json['notes'] as String?,
      wordData: wordData,
      nextReview: json['next_review'] != null 
          ? DateTime.parse(json['next_review'] as String)
          : null,
      reviewCount: json['review_count'] as int? ?? 0,
      correctCount: json['correct_count'] as int? ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      exerciseScores: _defaultExerciseScores(),
    );
  }

  /// Calculate interval days from card data
  int _calculateIntervalDays(CardModel card) {
    if (card.nextReview == null || card.lastReviewed == null) return 0;
    return card.nextReview!.difference(card.lastReviewed!).inDays;
  }

  /// Create default exercise scores
  Map<ExerciseType, ExerciseScore> _defaultExerciseScores() {
    final scores = <ExerciseType, ExerciseScore>{};
    for (final type in ExerciseType.values) {
      if (type.isImplemented) {
        scores[type] = ExerciseScore.initial(type);
      }
    }
    return scores;
  }
}
