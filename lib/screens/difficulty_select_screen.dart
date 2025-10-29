import 'package:flutter/material.dart';
import '../managers/difficulty_manager.dart';
import '../managers/sound_manager.dart';

/// 난이도 선택 화면 (전체 화면)
class DifficultySelectScreen extends StatelessWidget {
  const DifficultySelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_pool.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 제목
                  Text(
                    '로티의 기억력 게임',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'TJJoyofsinging',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          offset: const Offset(3, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 부제목
                  Text(
                    '난이도를 선택하세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'TJJoyofsinging',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  // 쉬움 버튼
                  _DifficultyButton(
                    difficulty: Difficulty.easy,
                    onPressed: () => _selectDifficulty(context, Difficulty.easy),
                  ),
                  const SizedBox(height: 20),
                  // 중간 버튼
                  _DifficultyButton(
                    difficulty: Difficulty.medium,
                    onPressed: () => _selectDifficulty(context, Difficulty.medium),
                  ),
                  const SizedBox(height: 20),
                  // 어려움 버튼
                  _DifficultyButton(
                    difficulty: Difficulty.hard,
                    onPressed: () => _selectDifficulty(context, Difficulty.hard),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectDifficulty(BuildContext context, Difficulty difficulty) async {
    // iOS 크롬 대응: 사용자 제스처 내에서 즉시 오디오 언락
    SoundManager().enableSoundSync();

    // 난이도 설정
    DifficultyManager().setDifficulty(difficulty);

    // 게임 화면으로 이동
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/game');
    }
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
        width: 320,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _isPressed ? _getPressedColor() : _getButtonColor(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              widget.difficulty.displayName,
              style: const TextStyle(
                fontFamily: 'TJJoyofsinging',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black,
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
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
