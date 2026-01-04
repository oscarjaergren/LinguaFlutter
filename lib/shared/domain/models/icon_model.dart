import 'package:json_annotation/json_annotation.dart';

part 'icon_model.g.dart';

@JsonSerializable()
class IconModel {
  final String id;
  final String name;
  final String set;
  final String category;
  final List<String> tags;
  final String svgUrl;

  const IconModel({
    required this.id,
    required this.name,
    required this.set,
    required this.category,
    required this.tags,
    required this.svgUrl,
  });

  factory IconModel.fromJson(Map<String, dynamic> json) =>
      _$IconModelFromJson(json);

  Map<String, dynamic> toJson() => _$IconModelToJson(this);

  /// Creates an IconModel from Iconify API response
  factory IconModel.fromIconify({
    required String iconId,
    String? collectionName,
    List<String>? tags,
  }) {
    final parts = iconId.split(':');
    final set = parts.length > 1 ? parts[0] : 'unknown';
    final name = parts.length > 1 ? parts[1] : iconId;

    return IconModel(
      id: iconId,
      name: name.replaceAll('-', ' ').replaceAll('_', ' '),
      set: set,
      category: collectionName ?? 'Unknown',
      tags: tags ?? [],
      svgUrl: 'https://api.iconify.design/$iconId.svg',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
