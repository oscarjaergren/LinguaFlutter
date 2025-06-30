// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardModel _$CardModelFromJson(Map<String, dynamic> json) => CardModel(
  id: json['id'] as String,
  frontText: json['frontText'] as String,
  backText: json['backText'] as String,
  icon: json['icon'] == null
      ? null
      : IconModel.fromJson(json['icon'] as Map<String, dynamic>),
  frontLanguage: json['frontLanguage'] as String,
  backLanguage: json['backLanguage'] as String,
  category: json['category'] as String,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
  reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
  correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
  lastReviewed: json['lastReviewed'] == null
      ? null
      : DateTime.parse(json['lastReviewed'] as String),
  nextReview: json['nextReview'] == null
      ? null
      : DateTime.parse(json['nextReview'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isFavorite: json['isFavorite'] as bool? ?? false,
  isArchived: json['isArchived'] as bool? ?? false,
);

Map<String, dynamic> _$CardModelToJson(CardModel instance) => <String, dynamic>{
  'id': instance.id,
  'frontText': instance.frontText,
  'backText': instance.backText,
  'icon': instance.icon,
  'frontLanguage': instance.frontLanguage,
  'backLanguage': instance.backLanguage,
  'category': instance.category,
  'tags': instance.tags,
  'difficulty': instance.difficulty,
  'reviewCount': instance.reviewCount,
  'correctCount': instance.correctCount,
  'lastReviewed': instance.lastReviewed?.toIso8601String(),
  'nextReview': instance.nextReview?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isFavorite': instance.isFavorite,
  'isArchived': instance.isArchived,
};
