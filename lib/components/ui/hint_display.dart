import 'package:flame/components.dart';
import 'package:flutter/material.dart' show TextStyle, FontWeight;
import 'dart:ui' show Canvas, Color, Paint, PaintingStyle, RRect, Radius, Rect;

/// 힌트 개수를 표시하는 UI 컴포넌트 (SpriteComponent 사용)
class HintDisplay extends PositionComponent {
  int _hintCount = 0;
  late TextComponent _hintText;
  late SpriteComponent _hintIcon;

  HintDisplay({
    required Vector2 position,
  }) : super(
          position: position,
          anchor: Anchor.topLeft,
          priority: 100, // UI가 카드 위에 렌더링되도록 높은 우선순위
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    print('[HintDisplay] Loading at position: $position');

    // 힌트 아이콘 스프라이트 로드
    final hintSprite = await Sprite.load('hint.png');

    // 힌트 아이콘 (SpriteComponent)
    _hintIcon = SpriteComponent(
      sprite: hintSprite,
      size: Vector2(28, 28),
      position: Vector2(8, 6),
    );
    add(_hintIcon);

    // 힌트 개수 텍스트
    _hintText = TextComponent(
      text: 'x $_hintCount',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFFFFF), // 흰색
        ),
      ),
      position: Vector2(38, 8),
    );
    add(_hintText);

    // 초기 크기 설정
    size = Vector2(80, 40);

    print('[HintDisplay] Loaded with initial count: $_hintCount');
  }

  @override
  void render(Canvas canvas) {
    // 배경 그리기 (검은색 반투명)
    final backgroundPaint = Paint()
      ..color = const Color(0x99000000) // 60% 불투명도
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFFFFFFF) // 흰색
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(10),
    );

    canvas.drawRRect(rRect, backgroundPaint);
    canvas.drawRRect(rRect, borderPaint);

    super.render(canvas);
  }

  /// 힌트 개수 업데이트
  void updateHintCount(int count) {
    _hintCount = count;
    _hintText.text = 'x $_hintCount';
    print('[HintDisplay] Hint count updated to: $_hintCount');
  }
}
