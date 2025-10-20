import 'package:flame/components.dart';

/// Displays hearts representing remaining lives
class LivesDisplay extends PositionComponent {
  final int _maxLives;
  int _currentLives = 3;
  final List<SpriteComponent> _heartSprites = [];

  late Sprite _fullHeartSprite;
  late Sprite _emptyHeartSprite;

  LivesDisplay({
    required Vector2 position,
    required int maxLives,
  })  : _maxLives = maxLives,
        _currentLives = maxLives,
        super(position: position, anchor: Anchor.topRight);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    print('[LivesDisplay] Loading at position: $position');

    // Load heart sprites
    _fullHeartSprite = await Sprite.load('heart_full.png');
    _emptyHeartSprite = await Sprite.load('heart_empty.png');

    // Create heart sprites
    for (int i = 0; i < _maxLives; i++) {
      final heart = SpriteComponent(
        sprite: _fullHeartSprite,
        size: Vector2(40, 40),
        position: Vector2(-i * 45.0, 0),
        anchor: Anchor.topRight,
      );
      _heartSprites.add(heart);
      add(heart);
    }

    print('[LivesDisplay] Loaded ${_heartSprites.length} hearts');
  }

  /// Update the number of lives displayed
  void updateLives(int lives) {
    _currentLives = lives;
    print('[LivesDisplay] Lives updated to: $_currentLives');

    // Update heart sprites
    for (int i = 0; i < _heartSprites.length; i++) {
      if (i < _currentLives) {
        _heartSprites[i].sprite = _fullHeartSprite;
      } else {
        _heartSprites[i].sprite = _emptyHeartSprite;
      }
    }
  }
}
