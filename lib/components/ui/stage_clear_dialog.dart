import 'package:flutter/material.dart';
import 'package:lotty_memory_game/components/ui/outlined_text.dart';

/// 스테이지 클리어 다이얼로그
class StageClearDialog extends StatelessWidget {
  final VoidCallback onNext;
  final int currentStage;
  final Duration elapsedTime;

  const StageClearDialog({
    super.key,
    required this.onNext,
    required this.currentStage,
    required this.elapsedTime,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 상단 여백
                SizedBox(height: 80, 
                  child: Center(
                    child: OutlinedText(
                            '스테이지 $currentStage 완료',
                            style: const TextStyle(
                              fontFamily: 'TJJoyofsinging',
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Color(0xffF4256D),
                            ),
                            outlineColor: Color(0xFFFFE5EF),
                            outlineWidth: 7.0,
                          ),
                  ),
                ),

                // 내용 영역
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xffFFCCDE),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 22),
                        Text(
                         _formatDuration(elapsedTime),
                         style: TextStyle(
                           fontFamily: 'TJJoyofsinging',
                           fontSize: 32,
                           fontWeight: FontWeight.w800,
                           color: Color(0xff300313).withValues(alpha: 0.9),
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
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D8B),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.white,
                    width: 6,
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
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
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
