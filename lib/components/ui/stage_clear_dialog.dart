import 'package:flutter/material.dart';

/// 스테이지 클리어 다이얼로그
class StageClearDialog extends StatelessWidget {
  final VoidCallback onNext;
  final int currentStage;

  const StageClearDialog({
    super.key,
    required this.onNext,
    required this.currentStage,
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
            margin: const EdgeInsets.only(bottom: 40), // 버튼 공간 확보
            decoration: BoxDecoration(
              color: const Color(0xffFF99BD),
              borderRadius: BorderRadius.circular(48),
              border: Border.all(
                color: Colors.white,
                width: 7,
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

                // 내용 영역
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xffFFCCDE),
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24),

                        // 스테이지 클리어 텍스트
                        const Text(
                          'Stage Clear!',
                          style: TextStyle(
                            fontFamily: 'TJJoyofsinging',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xff300313),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 현재 스테이지 번호
                        Text(
                          'Stage $currentStage 완료',
                          style: const TextStyle(
                            fontFamily: 'TJJoyofsinging',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff300313),
                          ),
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
                onNext();
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
                  '다음 스테이지',
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
