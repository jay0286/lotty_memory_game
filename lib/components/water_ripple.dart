import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/game_config.dart';

/// Water ripple effect that expands and fades out
class WaterRipple extends PositionComponent {
  final Vector2 startPosition;
  final double maxRadius;
  final double duration;
  final Color rippleColor;

  double _currentTime = 0.0;
  double _currentRadius = 0.0;
  double _currentAlpha = 0.2;

  WaterRipple({
    required this.startPosition,
    this.maxRadius = 80.0,
    this.duration = GameConfig.rippleDuration,
    this.rippleColor = GameConfig.rippleColor,
  }) : super(
          position: startPosition,
          anchor: Anchor.center,
          priority: GameConfig.ripplePriority,
        );

  @override
  void update(double dt) {
    super.update(dt);

    _currentTime += dt;

    // Calculate progress (0.0 to 1.0)
    final progress = (_currentTime / duration).clamp(0.0, 1.0);

    // Expand radius with easing
    _currentRadius = maxRadius * _easeOut(progress);

    // Fade out alpha
    _currentAlpha = 1.0 - progress;

    // Remove when animation is complete
    if (_currentTime >= duration && parent != null) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_currentAlpha <= 0) return;

    // Draw multiple ripple rings for a more realistic effect
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = GameConfig.rippleStrokeWidth
      ..color = rippleColor.withValues(alpha: _currentAlpha * GameConfig.rippleOpacityMain);

    // Main ripple
    canvas.drawCircle(Offset.zero, _currentRadius, paint);

    // Secondary ripple (slightly smaller and delayed)
    if (_currentRadius > maxRadius * 0.3) {
      final secondaryRadius = _currentRadius * 0.7;
      final secondaryAlpha = _currentAlpha * GameConfig.rippleOpacitySecondary;
      paint.color = rippleColor.withValues(alpha: secondaryAlpha);
      paint.strokeWidth = GameConfig.rippleStrokeWidthSecondary;
      canvas.drawCircle(Offset.zero, secondaryRadius, paint);
    }
  }

  /// Ease-out function for smooth expansion
  double _easeOut(double t) {
    return 1 - math.pow(1 - t, 3).toDouble();
  }
}
