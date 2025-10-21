import 'dart:ui' as ui;
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/extensions.dart';
import 'sprite_data.dart';
import 'xml_parser.dart';

/// Card category group - defines which categories can match with each other
enum CardCategoryGroup {
  numeric,     // numbers and dice can match with each other (1 = 1)
  shells,      // shell themed cards
  fruits,      // fruit themed cards
  desserts,    // dessert themed cards
  shape,       // geometric shape cards
  beachballs,  // beach ball cards
  fish,        // fish cards
  sealife,     // sea creature cards
  beachgear,   // beach gear cards
}

/// Card category types for different sprite sets
enum CardCategory {
  numbers,
  dice,
  shells,
  fruits,
  desserts,
  shapes,
  beachballs,
  fish,
  sealife,
  beachgear,
}

/// Extension to get the group for each category
extension CardCategoryExtension on CardCategory {
  CardCategoryGroup get group {
    switch (this) {
      case CardCategory.numbers:
      case CardCategory.dice:
        return CardCategoryGroup.numeric;
      case CardCategory.shells:
        return CardCategoryGroup.shells;
      case CardCategory.fruits:
        return CardCategoryGroup.fruits;
      case CardCategory.desserts:
        return CardCategoryGroup.desserts;
      case CardCategory.shapes:
        return CardCategoryGroup.shape;
      case CardCategory.beachballs:
        return CardCategoryGroup.beachballs;
      case CardCategory.fish:
        return CardCategoryGroup.fish;
      case CardCategory.sealife:
        return CardCategoryGroup.sealife;
      case CardCategory.beachgear:
        return CardCategoryGroup.beachgear;
    }
  }
}

/// Manages all game assets including sprites and images
class AssetManager {
  static AssetManager? _instance;
  static AssetManager get instance => _instance ??= AssetManager._();

  AssetManager._();

  static const Map<CardCategory, _CategorySpriteConfig> _spriteConfigs = {
    CardCategory.numbers: _CategorySpriteConfig(
      pattern: 'number card_{index}.png',
      count: 9,
    ),
    CardCategory.dice: _CategorySpriteConfig(
      pattern: 'dice card_{index}.png',
      count: 9,
    ),
    CardCategory.shells: _CategorySpriteConfig(
      pattern: 'shell_card_{index}.png',
      count: 5,
    ),
    CardCategory.fruits: _CategorySpriteConfig(
      pattern: 'fruit_card_{index}.png',
      count: 5,
    ),
    CardCategory.desserts: _CategorySpriteConfig(
      pattern: 'dessert_card_{index}.png',
      count: 5,
    ),
    CardCategory.shapes: _CategorySpriteConfig(
      pattern: 'shape_card_{index}.png',
      count: 5,
    ),
    CardCategory.beachballs: _CategorySpriteConfig(
      pattern: 'beachball_card_{index}.png',
      count: 5,
    ),
    CardCategory.fish: _CategorySpriteConfig(
      pattern: 'fish_card_{index}.png',
      count: 5,
    ),
    CardCategory.sealife: _CategorySpriteConfig(
      pattern: 'sealife_card_{index}.png',
      count: 5,
    ),
    CardCategory.beachgear: _CategorySpriteConfig(
      pattern: 'beachgear_card_{index}.png',
      count: 5,
    ),
  };

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
      'assets/spritesheet_match_numbers2.xml',
    );

    // Parse tubes XML
    _tubesAtlasData = await SpriteSheetParser.parseXml(
      'assets/spritesheet_match_tubes.xml',
    );

    // Load sprite sheet images
    _numbersImage = await Flame.images.load(
      'spritesheet_match_numbers2.png',
    );

    _tubesImage = await Flame.images.load(
      'spritesheet_match_tubes.png',
    );

    _isLoaded = true;

    // Build category sprite maps AFTER setting _isLoaded = true
    _categorySprites.clear();
    for (final entry in _spriteConfigs.entries) {
      final sprites = _buildSprites(entry.value);
      if (sprites.isNotEmpty) {
        _categorySprites[entry.key] = sprites;
      }
    }
  }

  /// Get sprite by name from the card atlas
  Sprite? _getCardSpriteByName(String name) {
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

  List<Sprite> _buildSprites(_CategorySpriteConfig config) {
    final sprites = <Sprite>[];
    for (int i = 1; i <= config.count; i++) {
      final index = i.toString().padLeft(config.padWidth, '0');
      final spriteName = config.pattern.replaceAll('{index}', index);
      final sprite = _getCardSpriteByName(spriteName);
      if (sprite != null) {
        sprites.add(sprite);
      }
    }
    return sprites;
  }
}

class _CategorySpriteConfig {
  final String pattern;
  final int count;
  final int padWidth;

  const _CategorySpriteConfig({
    required this.pattern,
    required this.count,
    this.padWidth = 2,
  });
}
