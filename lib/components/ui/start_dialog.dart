import 'package:flutter/material.dart';
import 'game_dialog.dart';

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
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GameDialog(
          title: '로티 메모리',
          message: '뒤집어진 튜브의 숫자를 기억해\n같은 숫자 두 가지를 짝지어 봐!',
          buttonText: '시작하기',
          showCloseButton: false,
          overlappingButton: true, // 버튼이 다이얼로그에 반쯤 걸치도록
          onButtonPressed: () {
            Navigator.of(context).pop();
            onStart();
          },
          customContent: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 목표 아이콘
              Column(
                children: [
                  // 목표 이미지
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
                        padding: const EdgeInsets.only(top: 10.0,right: 4),
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
                  // 목표 텍스트
                ],
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
              const SizedBox(height: 16),
            ],
          ),
        ),
        // 리더보드 가기 버튼 (다이얼로그 아래)
        if (onShowLeaderboard != null)
          Positioned(
            bottom: 220,
            child: TextButton(
              onPressed: onShowLeaderboard,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child:  Text(
                '랭킹 보러가기',
                style: TextStyle(
                  fontFamily: 'TJJoyofsinging',
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha:0.7),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
