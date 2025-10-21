import 'package:flutter/material.dart';
import 'outlined_text.dart';

/// 공용 게임 다이얼로그 컴포넌트
/// 튜토리얼, 안내 메시지 등에 재사용 가능
class GameDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Widget? customContent;
  final bool showCloseButton;
  final bool overlappingButton; // 버튼이 다이얼로그에 반쯤 걸치도록

  const GameDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.customContent,
    this.showCloseButton = true,
    this.overlappingButton = false,
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
            margin: overlappingButton && buttonText != null
                ? const EdgeInsets.only(bottom: 32) // 버튼 공간 확보
                : EdgeInsets.zero,
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
                  child: 
                  Center(
                    child: OutlinedText(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'TJJoyofsinging',
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color:Color(0xFFF4256D),
                            ),
                            outlineColor:  Color(0xFFE5EEFF),
                            outlineWidth: 7.0,
                          ),
                  ),
                ),
                // 내용
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    8,
                    0,
                    8,
                    8//overlappingButton && buttonText != null ? 40 : 24, // 버튼 겹침 시 하단 여백 증가
                  ),
                  child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xffFFCCDE), 
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
                  ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          const SizedBox(height: 24),
                        // 커스텀 콘텐츠 또는 메시지
                        if (customContent != null)
                          customContent!
                        else
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'TJJoyofsinging',
                              fontSize: 18,
                              color: Colors.white,
                              height: 1.5,
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
          if (overlappingButton && buttonText != null)
            Positioned(
              bottom: 0,
              child: GestureDetector(
                onTap: onButtonPressed ?? () => Navigator.of(context).pop(),
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
                  child: Text(
                    buttonText!,
                    style: const TextStyle(
                      fontFamily: 'TJJoyofsinging',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
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

/// 비디오/미디어 재생 다이얼로그
class MediaDialog extends StatelessWidget {
  final String title;
  final String videoUrl;
  final VoidCallback? onClose;

  const MediaDialog({
    super.key,
    required this.title,
    required this.videoUrl,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF2C5F8D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white,
            width: 4,
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
            // 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E4A6F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onClose?.call();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // 비디오 플레이어 영역 (플레이스홀더)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.play_circle_fill,
                              size: 80,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              // TODO: 비디오 재생 구현
                              print('Play video: $videoUrl');
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '비디오 재생',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
