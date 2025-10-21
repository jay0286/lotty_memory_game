import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:ui' show Canvas, Color, ImageFilter, Paint;
import 'dart:math' as math;
import 'water_ripple.dart';
import '../config/game_config.dart';

/// Card state enum
enum CardState {
  faceDown, // Shows pig tube
  faceUp, // Shows number
  matched, // Card has been matched
}

/// Powerup type enum
enum PowerupType {
  none,
  hint,  // 💡 Reveals all cards for 1 second
  heart, // ❤️ Restores 1 life
}

/// Match animation type
enum MatchAnimationType {
  splash, // Jump and splash
}

/// Fail animation type
enum FailAnimationType {
  shake, // Shake left and right
}

/// Represents a memory card with a pig tube on the back and a number on the front
class PigCard extends SpriteComponent with TapCallbacks {
  final Sprite backSprite; // Pig tube sprite
  final Sprite frontSprite; // Number sprite
  final int cardValue; // The value this card represents
  final Function(PigCard)? onTap;

  CardState _state = CardState.faceDown;
  CardState get state => _state;
  bool get isCollisionEnabled => _collisionEnabled;
  bool get isPlayingMatchAnimation => _isPlayingMatchAnimation;

  // Animation properties
  double _flipProgress = 0.0; // 0.0 = face down, 1.0 = face up
  bool _isFlipping = false;
  static const double _flipDuration = GameConfig.cardFlipDuration;

  // Floating movement properties
  Vector2 velocity = Vector2.zero();
  double floatSpeed = GameConfig.cardFloatSpeed;
  double floatTime = 0.0; // accumulated time for sin/cos calculations
  final math.Random _random = math.Random();

  // Movement parameters
  late double _floatOffsetX;
  late double _floatOffsetY;
  late double _floatFrequencyX;
  late double _floatFrequencyY;

  // Water ripple parameters
  double _rippleTimer = 0.0;
  final double _rippleInterval = GameConfig.rippleInterval;

  // Match/Fail animation properties
  bool _isPlayingMatchAnimation = false;
  bool _isPlayingFailAnimation = false;
  double _animationTimer = 0.0;
  Vector2? _originalPosition;
  final double _originalAlpha = 1.0;
  Function()? _onFailAnimationComplete;

  // Collision detection flag
  bool _collisionEnabled = true;

  // Powerup properties
  PowerupType powerupType = PowerupType.none;
  bool get hasPowerup => powerupType != PowerupType.none;

  static Sprite? _hintIconSprite;
  static Sprite? _heartIconSprite;
  static Future<void>? _iconLoadFuture;
  static const double _powerupPulseSpeed = 5.0;
  static const double _powerupPulseAmplitude = 0.08;
  static const double _powerupPulseSquish = 0.01;
  double _powerupAnimTime = 0.0;

  PigCard({
    required this.backSprite,
    required this.frontSprite,
    required this.cardValue,
    required Vector2 position,
    required Vector2 size,
    this.onTap,
  }) : super(
          sprite: backSprite,
          position: position,
          size: size,
          anchor: Anchor.center,
        ) {
    // Initialize random floating parameters for each card
    _floatOffsetX = _random.nextDouble() * math.pi * 2;
    _floatOffsetY = _random.nextDouble() * math.pi * 2;
    _floatFrequencyX = GameConfig.cardFloatFrequencyMin +
        _random.nextDouble() * (GameConfig.cardFloatFrequencyMax - GameConfig.cardFloatFrequencyMin);
    _floatFrequencyY = GameConfig.cardFloatFrequencyMin +
        _random.nextDouble() * (GameConfig.cardFloatFrequencyMax - GameConfig.cardFloatFrequencyMin);

    // Initialize random velocity
    final angle = _random.nextDouble() * math.pi * 2;
    velocity = Vector2(
      math.cos(angle) * floatSpeed,
      math.sin(angle) * floatSpeed,
    );
  }

  static Future<void> _ensurePowerupIconsLoaded() {
    return _iconLoadFuture ??= () async {
      _hintIconSprite ??= await Sprite.load('hint_item.png');
      _heartIconSprite ??= await Sprite.load('heart_item.png');
    }();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _ensurePowerupIconsLoaded();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_state == CardState.matched || _isFlipping) return;
    // Don't flip here - let the game logic handle it
    onTap?.call(this);
  }

  /// Flip the card (toggle between face up and face down)
  void flip() {
    if (_state == CardState.matched) return;

    // Toggle state
    if (_state == CardState.faceDown) {
      _state = CardState.faceUp;
    } else {
      _state = CardState.faceDown;
    }

    _isFlipping = true;
  }

  /// Flip to face up
  void flipToFaceUp() {
    if (_state == CardState.faceUp) return;
    _state = CardState.faceUp;
    _isFlipping = true;
  }

  /// Flip to face down
  void flipToFaceDown() {
    if (_state == CardState.faceDown) return;
    _state = CardState.faceDown;
    _isFlipping = true;
  }

  /// Mark card as matched and play success animation
  void setMatched() {
    _state = CardState.matched;
    _playMatchSuccessAnimation();
  }

  /// Play match success animation (splash only)
  void _playMatchSuccessAnimation() {
    // First flip to back side
    sprite = backSprite;
    _flipProgress = 0.0;
    _state = CardState.matched;

    _isPlayingMatchAnimation = true;
    _animationTimer = 0.0;
    _originalPosition = position.clone();

    // Disable collision detection during animation
    _collisionEnabled = false;

    // Create large ripple effect on match
    _createMatchSuccessRipple();
  }

  /// Play match fail animation
  void playMatchFailAnimation({Function()? onComplete}) {
    _isPlayingFailAnimation = true;
    _animationTimer = 0.0;
    _originalPosition = position.clone();
    _onFailAnimationComplete = onComplete;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (hasPowerup && _state == CardState.faceDown) {
      _powerupAnimTime += dt;
    } else if (_powerupAnimTime != 0.0) {
      _powerupAnimTime = 0.0;
    }

    // Update match success animation
    if (_isPlayingMatchAnimation) {
      _updateMatchSuccessAnimation(dt);
      return; // Don't update other animations while playing match animation
    }

    // Update match fail animation
    if (_isPlayingFailAnimation) {
      _updateMatchFailAnimation(dt);
      return; // Don't update other animations while playing fail animation
    }

    // Update floating movement
    _updateFloatingMovement(dt);

    // Generate water ripples periodically
    _rippleTimer += dt;

    if (_rippleTimer >= _rippleInterval) {
      _createWaterRipple();
      _rippleTimer = 0.0;
    }

    if (_isFlipping) {
      // Determine target flip progress based on state
      final targetProgress = _state == CardState.faceUp ? 1.0 : 0.0;

      // Animate towards target
      if (_flipProgress < targetProgress) {
        _flipProgress = math.min(1.0, _flipProgress + dt / _flipDuration);
      } else if (_flipProgress > targetProgress) {
        _flipProgress = math.max(0.0, _flipProgress - dt / _flipDuration);
      }

      // Update sprite based on flip progress
      if (_flipProgress < 0.5) {
        sprite = backSprite;
      } else {
        sprite = frontSprite;
      }

      // Apply scale effect for flip animation
      final scaleX = math.cos(_flipProgress * math.pi).abs();
      scale = Vector2(scaleX, 1.0);

      // Check if animation is complete
      if ((_state == CardState.faceUp && _flipProgress >= 1.0) ||
          (_state == CardState.faceDown && _flipProgress <= 0.0)) {
        _isFlipping = false;
        scale = Vector2.all(1.0);
      }
    }
  }

  /// Update floating movement with sin/cos for smooth motion
  void _updateFloatingMovement(double dt) {
    floatTime += dt;

    // Add sinusoidal movement for natural floating effect
    final floatX = math.sin(floatTime * _floatFrequencyX + _floatOffsetX) * 2;
    final floatY = math.cos(floatTime * _floatFrequencyY + _floatOffsetY) * 2;

    // Update position with velocity and floating offset
    position.add(Vector2(
      velocity.x * dt + floatX * dt,
      velocity.y * dt + floatY * dt,
    ));
  }

  /// Create a water ripple effect at the card's current position
  void _createWaterRipple() {
    if (parent == null) return;

    final ripple = WaterRipple(
      startPosition: position.clone(),
      maxRadius: size.x * GameConfig.rippleMaxRadiusMultiplier,
      duration: GameConfig.rippleDuration,
    );

    // Add ripple to parent (the game world) so it stays in place
    parent!.add(ripple);
  }

  /// Create a large ripple for match success
  void _createMatchSuccessRipple() {
    if (parent == null) return;

    final ripple = WaterRipple(
      startPosition: position.clone(),
      maxRadius: size.x * GameConfig.rippleMaxRadiusMultiplier * GameConfig.matchSuccessRippleMultiplier,
      duration: GameConfig.rippleDuration * 1.5,
    );

    parent!.add(ripple);
  }

  /// Update match success animation
  void _updateMatchSuccessAnimation(double dt) {
    _animationTimer += dt;
    final progress = (_animationTimer / GameConfig.matchSuccessAnimationDuration).clamp(0.0, 1.0);

    if (_originalPosition == null) return;

    // Remove card when animation completes
    if (progress >= 1.0) {
      if (parent != null) {
        removeFromParent();
      }
      return; // Stop updating after removal
    }

    // Splash animation: jump up and fade out
    _updateSplashAnimation(progress);
  }

  /// Update splash animation (card jumps and disappears)
  void _updateSplashAnimation(double progress) {
    if (_originalPosition == null) return;

    // Parabolic jump trajectory
    final jumpProgress = math.sin(progress * math.pi);

    // Move up in arc
    position.y = _originalPosition!.y - (GameConfig.jumpAnimationHeight * jumpProgress);

    // Fade out in second half
    if (progress > 0.5) {
      opacity = 1.0 - ((progress - 0.5) * 2.0);
    }

    // Rotate while jumping
    angle = progress * math.pi * 2;

    // Scale pulse at peak
    final pulseProgress = math.sin(progress * math.pi);
    final scaleValue = 1.0 + (pulseProgress * 0.3);
    scale = Vector2.all(scaleValue);
  }

  /// Update match fail animation (shake)
  void _updateMatchFailAnimation(double dt) {
    _animationTimer += dt;
    final progress = (_animationTimer / GameConfig.matchFailAnimationDuration).clamp(0.0, 1.0);

    if (_originalPosition == null) return;

    if (progress < 1.0) {
      // Shake effect: fast oscillation that decreases over time
      final shakeFrequency = 20.0; // Hz
      final shakeAmount = GameConfig.shakeAnimationIntensity * (1.0 - progress);
      final offset = math.sin(_animationTimer * shakeFrequency * math.pi * 2) * shakeAmount;

      position.x = _originalPosition!.x + offset;
    } else {
      // Animation complete, return to original position
      position.x = _originalPosition!.x;
      _isPlayingFailAnimation = false;
      _originalPosition = null;

      // Call completion callback
      _onFailAnimationComplete?.call();
      _onFailAnimationComplete = null;
    }
  }

  /// Handle boundary collision - bounce off edges
  void handleBoundary(Vector2 gameSize) {
    final halfWidth = size.x / 2;
    final halfHeight = size.y / 2;

    // Left boundary
    if (position.x - halfWidth < 0) {
      position.x = halfWidth;
      velocity.x = velocity.x.abs();
    }
    // Right boundary
    else if (position.x + halfWidth > gameSize.x) {
      position.x = gameSize.x - halfWidth;
      velocity.x = -velocity.x.abs();
    }

    // Top boundary
    if (position.y - halfHeight < 0) {
      position.y = halfHeight;
      velocity.y = velocity.y.abs();
    }
    // Bottom boundary
    else if (position.y + halfHeight > gameSize.y) {
      position.y = gameSize.y - halfHeight;
      velocity.y = -velocity.y.abs();
    }
  }

  /// Check collision with another card
  bool collidesWith(PigCard other) {
    final distance = position.distanceTo(other.position);
    final minDistance = (size.x + other.size.x) / 2;
    return distance < minDistance;
  }

  /// Resolve collision with another card (push apart)
  void resolveCollision(PigCard other) {
    final direction = (position - other.position).normalized();
    final overlap = (size.x + other.size.x) / 2 - position.distanceTo(other.position);

    if (overlap > 0) {
      // Push cards apart
      position.add(direction * overlap * 0.5);
      other.position.add(direction * -overlap * 0.5);

      // Add some bounce by adjusting velocities
      final relativeVelocity = velocity - other.velocity;
      final velocityAlongDirection = relativeVelocity.dot(direction);

      if (velocityAlongDirection < 0) {
        final impulse = direction * velocityAlongDirection * GameConfig.cardBounceFactor;
        velocity.sub(impulse);
        other.velocity.add(impulse);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Render powerup icon if card has one and is face down
    if (hasPowerup && _state == CardState.faceDown) {
      _renderPowerupIcon(canvas);
    }
  }

  /// Render powerup icon on the card
  void _renderPowerupIcon(Canvas canvas) {
    final sprite = switch (powerupType) {
      PowerupType.hint => _hintIconSprite,
      PowerupType.heart => _heartIconSprite,
      _ => null,
    };

    if (sprite == null) {
      return;
    }

    final baseSize = size.x * 0.5;
    final pulse = math.sin(_powerupAnimTime * _powerupPulseSpeed);
    final scaleX = 1 + pulse * _powerupPulseAmplitude;
    final scaleY = 1 - pulse * _powerupPulseSquish;
    final width = baseSize * scaleX;
    final height = baseSize * 0.65 * scaleY;
    final position = Vector2(baseSize, -baseSize * 0.45);

    // final shadowPaint = Paint()
    //   ..color = const Color(0x55000000)
    //   ..imageFilter = ImageFilter.blur(sigmaX: 4, sigmaY: 4);
    // final shadowOffset = Vector2(width * 0.06, height * 0.08);

    // sprite.render(
    //   canvas,
    //   position: position + shadowOffset,
    //   size: Vector2(width, height),
    //   anchor: Anchor.center,
    //   overridePaint: shadowPaint,
    // );

    sprite.render(
      canvas,
      position: position,
      size: Vector2(width, height),
      anchor: Anchor.center,
    );
  }

  /// Reset card to initial state
  void reset() {
    _state = CardState.faceDown;
    _flipProgress = 0.0;
    _isFlipping = false;
    sprite = backSprite;
    scale = Vector2.all(1.0);
    powerupType = PowerupType.none; // Clear powerup
    _powerupAnimTime = 0.0;
  }
}
