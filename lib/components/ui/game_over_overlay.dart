import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// Displays game over or win message
class GameOverOverlay extends PositionComponent with TapCallbacks {
  final bool isWin;
  final int finalScore;
  final VoidCallback? onRestart;
  final String? customMessage;

  GameOverOverlay({
    required this.isWin,
    required this.finalScore,
    required Vector2 gameSize,
    this.onRestart,
    this.customMessage,
  }) : super(
          size: gameSize,
          position: Vector2.zero(),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Semi-transparent background
    final background = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.black.withValues(alpha: 0.7),
    );
    add(background);

    // Title text
    final title = TextComponent(
      text: isWin ? 'You Won!' : 'Game Over!',
      position: Vector2(size.x / 2, size.y / 2 - 80),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: isWin ? Colors.yellow : Colors.red,
          fontSize: 64,
          fontFamily: 'TJJoyofsinging',
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              color: Colors.black,
              offset: Offset(3, 3),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
    add(title);

    // Score text
    final scoreText = TextComponent(
      text: 'Final Score: $finalScore',
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontFamily: 'TJJoyofsinging',
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
    add(scoreText);

    // Restart hint text
    final hintText = TextComponent(
      text: customMessage ?? 'Tap to Restart',
      position: Vector2(size.x / 2, size.y / 2 + 80),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 24,
          fontFamily: 'TJJoyofsinging',
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
    add(hintText);
  }

  @override
  void onTapDown(TapDownEvent event) {
    onRestart?.call();
  }
}
