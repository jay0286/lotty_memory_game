import 'package:flutter/foundation.dart';

/// Represents sprite data parsed from XML
class SpriteData {
  final String name;
  final double x;
  final double y;
  final double width;
  final double height;

  const SpriteData({
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  String toString() {
    return 'SpriteData(name: $name, x: $x, y: $y, w: $width, h: $height)';
  }
}

/// Atlas data containing all sprites
@immutable
class AtlasData {
  final String imagePath;
  final double width;
  final double height;
  final List<SpriteData> sprites;

  const AtlasData({
    required this.imagePath,
    required this.width,
    required this.height,
    required this.sprites,
  });

  SpriteData? getSpriteByName(String name) {
    try {
      return sprites.firstWhere((sprite) => sprite.name == name);
    } catch (e) {
      return null;
    }
  }
}
