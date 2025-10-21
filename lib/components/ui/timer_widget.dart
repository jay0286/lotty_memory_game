import 'package:flutter/material.dart';

/// Flutter OSD widget for displaying elapsed time
class TimerWidget extends StatelessWidget {
  final ValueNotifier<Duration> elapsedTimeNotifier;

  const TimerWidget({
    super.key,
    required this.elapsedTimeNotifier,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: elapsedTimeNotifier,
      builder: (context, elapsed, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               Icon(
                Icons.timer,
                size: 32,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                _formatDuration(elapsed),
                style:  TextStyle(
                  fontFamily: 'TJJoyofsinging',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
