// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'icon_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IconModel _$IconModelFromJson(Map<String, dynamic> json) => IconModel(
  id: json['id'] as String,
  name: json['name'] as String,
  set: json['set'] as String,
  category: json['category'] as String,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  svgUrl: json['svgUrl'] as String,
);

Map<String, dynamic> _$IconModelToJson(IconModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'set': instance.set,
  'category': instance.category,
  'tags': instance.tags,
  'svgUrl': instance.svgUrl,
};
