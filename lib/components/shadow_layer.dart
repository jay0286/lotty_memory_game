import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'pig_card.dart';
import '../config/game_config.dart';

/// Shadow layer that renders all card shadows below all cards
/// This ensures shadows never appear on top of other cards
class ShadowLayer extends Component {
  final List<PigCard> cards;

  ShadowLayer({
    required this.cards,
  }) : super(priority: 5); // Lower priority than cards (10), renders first

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!GameConfig.shadowEnabled) return;

    // Render shadow for each card
    for (final card in cards) {
      // Skip if card is playing match animation (no shadow when jumping)
      if (card.isPlayingMatchAnimation) continue;

      // Skip if card has no parent (removed)
      if (card.parent == null) continue;

      _renderCardShadow(canvas, card);
    }
  }

  /// Render shadow for a single card
  void _renderCardShadow(Canvas canvas, PigCard card) {
    final shadowWidth = card.size.x * GameConfig.shadowWidthMultiplier;
    final shadowHeight = card.size.y * GameConfig.shadowHeightMultiplier;

    final shadowPaint = Paint()
      ..color = GameConfig.shadowColor.withValues(alpha: GameConfig.shadowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    // Save canvas state
    canvas.save();

    // Translate to card position
    canvas.translate(card.position.x, card.position.y);

    // Apply card scale if needed
    if (card.scale.x != 1.0 || card.scale.y != 1.0) {
      canvas.scale(card.scale.x, card.scale.y);
    }

    // Draw elliptical shadow below card
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(GameConfig.shadowOffsetX, GameConfig.shadowOffsetY),
        width: shadowWidth,
        height: shadowHeight,
      ),
      shadowPaint,
    );

    // Restore canvas state
    canvas.restore();
  }
}
