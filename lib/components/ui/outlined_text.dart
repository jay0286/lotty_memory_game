import 'package:flutter/material.dart';

/// 아웃라인(외곽선)이 있는 텍스트 위젯
class OutlinedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color outlineColor;
  final double outlineWidth;
  final TextAlign? textAlign;

  const OutlinedText(
    this.text, {
    super.key,
    this.style,
    this.outlineColor = Colors.white,
    this.outlineWidth = 2.0,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? const TextStyle();

    return Stack(
      children: [
        // 아웃라인 레이어 (그림자처럼 여러 방향으로)
        Text(
          text,
          textAlign: textAlign,
          style: textStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = outlineWidth
              ..color = outlineColor,
          ),
        ),
        // 메인 텍스트
        Text(
          text,
          textAlign: textAlign,
          style: textStyle,
        ),
      ],
    );
  }
}
