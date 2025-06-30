// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StreakModel _$StreakModelFromJson(Map<String, dynamic> json) => StreakModel(
  currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
  bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
  lastReviewDate: json['lastReviewDate'] == null
      ? null
      : DateTime.parse(json['lastReviewDate'] as String),
  totalReviewSessions: (json['totalReviewSessions'] as num?)?.toInt() ?? 0,
  totalCardsReviewed: (json['totalCardsReviewed'] as num?)?.toInt() ?? 0,
  dailyReviewCounts:
      (json['dailyReviewCounts'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const {},
  achievedMilestones:
      (json['achievedMilestones'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  streakStartDate: json['streakStartDate'] == null
      ? null
      : DateTime.parse(json['streakStartDate'] as String),
  bestStreakDate: json['bestStreakDate'] == null
      ? null
      : DateTime.parse(json['bestStreakDate'] as String),
);

Map<String, dynamic> _$StreakModelToJson(StreakModel instance) =>
    <String, dynamic>{
      'currentStreak': instance.currentStreak,
      'bestStreak': instance.bestStreak,
      'lastReviewDate': instance.lastReviewDate?.toIso8601String(),
      'totalReviewSessions': instance.totalReviewSessions,
      'totalCardsReviewed': instance.totalCardsReviewed,
      'dailyReviewCounts': instance.dailyReviewCounts,
      'achievedMilestones': instance.achievedMilestones,
      'streakStartDate': instance.streakStartDate?.toIso8601String(),
      'bestStreakDate': instance.bestStreakDate?.toIso8601String(),
    };
