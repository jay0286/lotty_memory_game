import 'package:flutter/material.dart';

/// 게임 오버 다이얼로그
class GameOverDialog extends StatefulWidget {
  final VoidCallback onRetry;
  final int currentStage;
  final Duration elapsedTime;
  final Future<void> Function(String playerName)? onSaveRanking;

  const GameOverDialog({
    super.key,
    required this.onRetry,
    required this.currentStage,
    required this.elapsedTime,
    this.onSaveRanking,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleRetry() async {
    debugPrint('=== GameOverDialog: _handleRetry called ===');

    if (widget.onSaveRanking != null) {
      final playerName = _nameController.text.trim().isEmpty
          ? 'Unknown'
          : _nameController.text.trim();

      debugPrint('Saving ranking with name: $playerName');
      setState(() => _isSaving = true);

      try {
        await widget.onSaveRanking!(playerName);
        debugPrint('Ranking save completed successfully');
      } catch (e) {
        debugPrint('Failed to save ranking: $e');
      }

      setState(() => _isSaving = false);
    } else {
      debugPrint('onSaveRanking callback is null!');
    }

    if (mounted) {
      Navigator.of(context).pop();
      widget.onRetry();
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
              border: Border.all(color: Colors.white, width: 8),
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
                      // 게임오버 캐릭터 이미지
                      Stack(
                        children: [
                          Image.asset(
                            'assets/images/game over.png',
                            width: 280,
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 110),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Stage ${widget.currentStage}',
                                    style: const TextStyle(
                                      fontFamily: 'TJJoyofsinging',
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDuration(widget.elapsedTime),
                                    style: const TextStyle(
                                      fontFamily: 'TJJoyofsinging',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 이름 입력 필드
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '이름 입력 (선택)',
                            hintStyle: TextStyle(
                              fontFamily: 'TJJoyofsinging',
                              fontSize: 16,
                              color: const Color(0xff300313).withValues(alpha: 0.5),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.8),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFFF4D8B),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFFF4D8B),
                                width: 3,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'TJJoyofsinging',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff300313),
                          ),
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 겹치는 버튼 (다이얼로그 하단에 반쯤 걸침)
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: _isSaving ? null : _handleRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D8B),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.white, width: 7),
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
