import 'package:flutter/material.dart';
import '../../managers/difficulty_manager.dart';
import 'outlined_text.dart';

/// 난이도 선택 다이얼로그
class DifficultySelectDialog extends StatelessWidget {
  final VoidCallback onDifficultySelected;

  const DifficultySelectDialog({
    super.key,
    required this.onDifficultySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: const Color(0xffFF99BD),
          borderRadius: BorderRadius.circular(48),
          border: Border.all(
            color: Colors.white,
            width: 8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 (제목)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Center(
                child: OutlinedText(
                  '난이도 선택',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'TJJoyofsinging',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF4256D),
                  ),
                  outlineColor: const Color(0xFFFFE5EF),
                  outlineWidth: 8.0,
                ),
              ),
            ),
            // 내용
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xffFFCCDE),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    // 쉬움 버튼
                    _DifficultyButton(
                      difficulty: Difficulty.easy,
                      onPressed: () {
                        DifficultyManager().setDifficulty(Difficulty.easy);
                        Navigator.of(context).pop();
                        onDifficultySelected();
                      },
                    ),
                    const SizedBox(height: 16),
                    // 중간 버튼
                    _DifficultyButton(
                      difficulty: Difficulty.medium,
                      onPressed: () {
                        DifficultyManager().setDifficulty(Difficulty.medium);
                        Navigator.of(context).pop();
                        onDifficultySelected();
                      },
                    ),
                    const SizedBox(height: 16),
                    // 어려움 버튼
                    _DifficultyButton(
                      difficulty: Difficulty.hard,
                      onPressed: () {
                        DifficultyManager().setDifficulty(Difficulty.hard);
                        Navigator.of(context).pop();
                        onDifficultySelected();
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 난이도 선택 버튼 위젯
class _DifficultyButton extends StatefulWidget {
  final Difficulty difficulty;
  final VoidCallback onPressed;

  const _DifficultyButton({
    required this.difficulty,
    required this.onPressed,
  });

  @override
  State<_DifficultyButton> createState() => _DifficultyButtonState();
}

class _DifficultyButtonState extends State<_DifficultyButton> {
  bool _isPressed = false;

  Color _getButtonColor() {
    switch (widget.difficulty) {
      case Difficulty.easy:
        return const Color(0xFF4CAF50); // 초록색
      case Difficulty.medium:
        return const Color(0xFF2196F3); // 파란색
      case Difficulty.hard:
        return const Color(0xFFF44336); // 빨간색
    }
  }

  Color _getPressedColor() {
    switch (widget.difficulty) {
      case Difficulty.easy:
        return const Color(0xFF45A049);
      case Difficulty.medium:
        return const Color(0xFF1976D2);
      case Difficulty.hard:
        return const Color(0xFFD32F2F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isPressed ? _getPressedColor() : _getButtonColor(),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              widget.difficulty.displayName,
              style: const TextStyle(
                fontFamily: 'TJJoyofsinging',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.difficulty.description,
              style: TextStyle(
                fontFamily: 'TJJoyofsinging',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
