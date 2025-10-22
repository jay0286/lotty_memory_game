import 'package:flutter/material.dart';
import 'outlined_text.dart';

/// 게임 시작 다이얼로그
class StartDialog extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback? onShowLeaderboard;

  const StartDialog({
    super.key,
    required this.onStart,
    this.onShowLeaderboard,
  });

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
            margin: const EdgeInsets.only(bottom: 160), // 버튼 공간 확보
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
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: Center(
                    child: OutlinedText(
                      '로티 메모리',
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
                        // 목표 아이콘
                        Center(
                          child: Stack(
                            children: [
                              Center(
                                child: Image.asset(
                                  'assets/images/icon_misssion.png',
                                  width: 80,
                                  height: 50,
                                ),
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10.0, right: 4),
                                  child: Text(
                                    '목표',
                                    style: TextStyle(
                                      fontFamily: 'TJJoyofsinging',
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xff300313),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '뒤집어진 튜브를 기억해\n 같은 짝을 찾아 봐!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'TJJoyofsinging',
                            fontSize: 23,
                            color: Color(0xff300313),
                            height: 1.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 시작하기 버튼 (다이얼로그 하단에 반쯤 걸침)
          Positioned(
            top: 290,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onStart();
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
                      '시작하기',
                      style: TextStyle(
                        fontFamily: 'TJJoyofsinging',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (onShowLeaderboard != null) ...[
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: onShowLeaderboard,
                    child: Container(
                      decoration: BoxDecoration(
                        color:   Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(36),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      child: Text(
                        '랭킹 보러가기',
                        style: TextStyle(
                          fontFamily: 'TJJoyofsinging',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
