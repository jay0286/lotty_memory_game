import 'package:flutter/material.dart';
import 'package:lotty_memory_game/components/ui/outlined_text.dart';

/// 게임 오버 다이얼로그
class GameOverDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final int currentStage;
  final Duration elapsedTime;
  final VoidCallback? onShowLeaderboard;

  const GameOverDialog({
    super.key,
    required this.onRetry,
    required this.currentStage,
    required this.elapsedTime,
    this.onShowLeaderboard,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleConfirm(BuildContext context) {
    // 콜백에서 처리하도록 위임 (pop은 콜백 내부에서 수행)
    if (onShowLeaderboard != null) {
      onShowLeaderboard!();
    }
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
            constraints: const BoxConstraints(maxWidth: 300),
            margin: const EdgeInsets.only(bottom: 40), // 버튼 공간 확보
            decoration: BoxDecoration(
              color: const Color(0xffFF99BD),
              borderRadius: BorderRadius.circular(48),
              border: Border.all(color: Colors.white, width: 7),
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
                // 내용 영역 (햇살 배경 + 게임오버 이미지)
                Container(
                  // width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xffFFCCDE),
                    borderRadius: BorderRadius.circular(42),
                    // 햇살 배경 이미지
                    image: const DecorationImage(
                      image: AssetImage('assets/images/dialog_bg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 42),
                      Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 100),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 60),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '시간 : ${_formatDuration(elapsedTime)}',
                                      style:  TextStyle(
                                        fontFamily: 'TJJoyofsinging',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black.withValues(alpha: 0.6),
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -50,
            child: 
              // 게임오버 캐릭터 이미지
              Image.asset(
                'assets/images/game over.png',
                width: 280,
                fit: BoxFit.contain,
              ),
          ),
          Positioned(
            top: 0,
            child: 
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 102),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedText(
                      '게임 오버',
                      style: const TextStyle(
                        fontFamily: 'TJJoyofsinging',
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF4256D),
                      ),  
                      outlineColor:  Color(0xFFFFE5EF),
                      outlineWidth: 6.0,
                    ),
                    Text(
                      '스테이지 $currentStage',
                      style: const TextStyle(
                        fontFamily: 'TJJoyofsinging',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 겹치는 버튼 (다이얼로그 하단에 반쯤 걸침)
          Positioned(
            bottom: 4,
            child: GestureDetector(
              onTap: () => _handleConfirm(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D8B),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.white, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontFamily: 'TJJoyofsinging',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // 겹치는 버튼 (다이얼로그 하단에 반쯤 걸침)
          Positioned(
            bottom: -120,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 38,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/gyunggido_logo.png',
                        width: 42,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Image.asset(
                        'assets/images/conjinwon_logo.png',
                        width: 54,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '2025년 K-콘텐츠 IP 융복합 제작지원 선정작',
                    style: TextStyle(
                      fontFamily: 'TJJoyofsinging',
                      fontSize: 11,
                      fontWeight: FontWeight.w200,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
