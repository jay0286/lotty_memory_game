import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math' as math;

/// Card state enum
enum CardState {
  faceDown, // Shows pig tube
  faceUp, // Shows number
  matched, // Card has been matched
}

/// Represents a memory card with a pig tube on the back and a number on the front
class PigCard extends SpriteComponent with TapCallbacks {
  final Sprite backSprite; // Pig tube sprite
  final Sprite frontSprite; // Number sprite
  final int cardValue; // The value this card represents
  final Function(PigCard)? onTap;

  CardState _state = CardState.faceDown;
  CardState get state => _state;

  // Animation properties
  double _flipProgress = 0.0; // 0.0 = face down, 1.0 = face up
  bool _isFlipping = false;
  static const double _flipDuration = 0.3; // seconds

  // Floating movement properties
  Vector2 velocity = Vector2.zero();
  double floatSpeed = 30.0; // pixels per second
  double floatTime = 0.0; // accumulated time for sin/cos calculations
  final math.Random _random = math.Random();

  // Movement parameters
  late double _floatOffsetX;
  late double _floatOffsetY;
  late double _floatFrequencyX;
  late double _floatFrequencyY;

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
    _floatFrequencyX = 0.5 + _random.nextDouble() * 0.5; // 0.5 to 1.0
    _floatFrequencyY = 0.5 + _random.nextDouble() * 0.5; // 0.5 to 1.0

    // Initialize random velocity
    final angle = _random.nextDouble() * math.pi * 2;
    velocity = Vector2(
      math.cos(angle) * floatSpeed,
      math.sin(angle) * floatSpeed,
    );
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

  /// Mark card as matched
  void setMatched() {
    _state = CardState.matched;
    // Could add special animation or effect here
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update floating movement
    _updateFloatingMovement(dt);

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
        final bounce = 0.8; // Bounciness factor
        final impulse = direction * velocityAlongDirection * bounce;
        velocity.sub(impulse);
        other.velocity.add(impulse);
      }
    }
  }

  /// Reset card to initial state
  void reset() {
    _state = CardState.faceDown;
    _flipProgress = 0.0;
    _isFlipping = false;
    sprite = backSprite;
    scale = Vector2.all(1.0);
  }
}
