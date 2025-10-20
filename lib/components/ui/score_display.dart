import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Displays the score on screen with custom rendering
class ScoreDisplay extends PositionComponent {
  int score = 0;
  late TextPaint textPaint;

  ScoreDisplay({
    required Vector2 position,
  }) : super(
          position: position,
          anchor: Anchor.topLeft,
          priority: 100, // High priority to render on top of cards
        ) {
    textPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontFamily: 'TJJoyofsinging',
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black54,
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  /// Update the displayed score
  void updateScore(int newScore) {
    score = newScore;
    print('[ScoreDisplay] Score updated to: $score');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    textPaint.render(canvas, 'Score: $score', Vector2.zero());
  }

  @override
  void onLoad() {
    super.onLoad();
    print('[ScoreDisplay] Loaded at position: $position');
  }
}
