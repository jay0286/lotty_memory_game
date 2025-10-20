import 'dart:ui' as ui;
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/extensions.dart';
import 'sprite_data.dart';
import 'xml_parser.dart';

/// Card category group - defines which categories can match with each other
enum CardCategoryGroup {
  numeric,  // numbers and dice can match with each other (1 = 1)
  color,    // colors only match with same color
  shape,    // shapes only match with same shape
}

/// Card category types for different sprite sets
enum CardCategory {
  numbers,
  dice,
  colors,
  shapes,
}

/// Extension to get the group for each category
extension CardCategoryExtension on CardCategory {
  CardCategoryGroup get group {
    switch (this) {
      case CardCategory.numbers:
      case CardCategory.dice:
        return CardCategoryGroup.numeric;
      case CardCategory.colors:
        return CardCategoryGroup.color;
      case CardCategory.shapes:
        return CardCategoryGroup.shape;
    }
  }
}

/// Manages all game assets including sprites and images
class AssetManager {
  static AssetManager? _instance;
  static AssetManager get instance => _instance ??= AssetManager._();

  AssetManager._();

  late AtlasData _numbersAtlasData;
  late AtlasData _tubesAtlasData;
  late ui.Image _numbersImage;
  late ui.Image _tubesImage;

  // Map to store sprites by category
  final Map<CardCategory, List<Sprite>> _categorySprites = {};

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// Load all assets
  Future<void> loadAssets() async {
    if (_isLoaded) return;

    // Parse numbers XML
    _numbersAtlasData = await SpriteSheetParser.parseXml(
      'assets/spritesheet_match_numbers.xml',
    );

    // Parse tubes XML
    _tubesAtlasData = await SpriteSheetParser.parseXml(
      'assets/spritesheet_match_tubes.xml',
    );

    // Load sprite sheet images
    _numbersImage = await Flame.images.load(
      'spritesheet_match_numbers.png',
    );

    _tubesImage = await Flame.images.load(
      'spritesheet_match_tubes.png',
    );

    _isLoaded = true;

    // Build category sprite maps AFTER setting _isLoaded = true
    _categorySprites[CardCategory.numbers] = getNumberCardSprites();
    _categorySprites[CardCategory.dice] = getDiceCardSprites();
    // TODO: Add colors and shapes when sprite sheets are ready
    // _categorySprites[CardCategory.colors] = getColorCardSprites();
    // _categorySprites[CardCategory.shapes] = getShapeCardSprites();
  }

  /// Get sprite by name from numbers atlas
  Sprite? getNumberSpriteByName(String name) {
    if (!_isLoaded) return null;

    final spriteData = _numbersAtlasData.getSpriteByName(name);
    if (spriteData == null) return null;

    return Sprite(
      _numbersImage,
      srcPosition: Vector2(spriteData.x, spriteData.y),
      srcSize: Vector2(spriteData.width, spriteData.height),
    );
  }

  /// Get sprite by name from tubes atlas
  Sprite? getTubeSpriteByName(String name) {
    if (!_isLoaded) return null;

    final spriteData = _tubesAtlasData.getSpriteByName(name);
    if (spriteData == null) return null;

    return Sprite(
      _tubesImage,
      srcPosition: Vector2(spriteData.x, spriteData.y),
      srcSize: Vector2(spriteData.width, spriteData.height),
    );
  }

  /// Get all number card sprites (number card_01 to number card_09)
  List<Sprite> getNumberCardSprites() {
    final sprites = <Sprite>[];
    for (int i = 1; i <= 9; i++) {
      final spriteName = 'number card_${i.toString().padLeft(2, '0')}.png';
      final sprite = getNumberSpriteByName(spriteName);
      if (sprite != null) {
        sprites.add(sprite);
      }
    }
    return sprites;
  }

  /// Get all dice card sprites (dice card_01 to dice card_09)
  List<Sprite> getDiceCardSprites() {
    final sprites = <Sprite>[];
    for (int i = 1; i <= 9; i++) {
      final spriteName = 'dice card_${i.toString().padLeft(2, '0')}.png';
      final sprite = getNumberSpriteByName(spriteName);
      if (sprite != null) {
        sprites.add(sprite);
      }
    }
    return sprites;
  }

  /// Get all tube pig sprites (tube_pig_01 to tube_pig_05)
  List<Sprite> getTubePigSprites() {
    final sprites = <Sprite>[];
    for (int i = 1; i <= 5; i++) {
      final spriteName = 'tube_pig_${i.toString().padLeft(2, '0')}.png';
      final sprite = getTubeSpriteByName(spriteName);
      if (sprite != null) {
        sprites.add(sprite);
      }
    }
    return sprites;
  }

  /// Get a random tube pig sprite
  Sprite? getRandomTubePigSprite() {
    final sprites = getTubePigSprites();
    if (sprites.isEmpty) return null;
    return sprites[(DateTime.now().millisecondsSinceEpoch % sprites.length)];
  }

  AtlasData get numbersAtlasData => _numbersAtlasData;
  AtlasData get tubesAtlasData => _tubesAtlasData;

  /// Get sprites for a specific category
  List<Sprite> getSpritesForCategory(CardCategory category) {
    return _categorySprites[category] ?? [];
  }
}
