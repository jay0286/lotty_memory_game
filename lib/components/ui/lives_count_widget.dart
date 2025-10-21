import 'package:flutter/material.dart';

/// Flutter OSD widget for displaying lives count
class LivesCountWidget extends StatelessWidget {
  final ValueNotifier<int> livesNotifier;

  const LivesCountWidget({
    super.key,
    required this.livesNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: livesNotifier,
      builder: (context, lives, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(32),
            // border: Border.all(
            //   color: const Color(0xFFFF4D8B),
            //   width: 2,
            // ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/heart_full.png',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'X $lives',
                style: const TextStyle(
                  fontFamily: 'TJJoyofsinging',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
