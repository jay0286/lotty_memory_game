import 'package:flutter/material.dart';

/// 게임 오버 다이얼로그
class GameOverDialog extends StatelessWidget {
  final VoidCallback onRetry;

  const GameOverDialog({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 메인 다이얼로그
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            margin: const EdgeInsets.only(bottom: 40), // 버튼 공간 확보
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
                // 상단 여백
                const SizedBox(height: 20),

                // 내용 영역 (햇살 배경 + 게임오버 이미지)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xffFFCCDE),
                      borderRadius: BorderRadius.circular(36),
                      // 햇살 배경 이미지
                      image: const DecorationImage(
                        image: AssetImage('assets/images/dialog_bg.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24),

                        // 게임오버 캐릭터 이미지
                        Image.asset(
                          'assets/images/game over.png',
                          width: 280,
                          height: 180,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(height: 42),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 겹치는 버튼 (다이얼로그 하단에 반쯤 걸침)
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D8B),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.white,
                    width: 7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  '다시하기',
                  style: TextStyle(
                    fontFamily: 'TJJoyofsinging',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
