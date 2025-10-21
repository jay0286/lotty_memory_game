import 'package:flutter/material.dart';

/// Flutter OSD widget for displaying stage number and name
class StageInfoWidget extends StatelessWidget {
  final int stageNumber;
  final String stageName;

  const StageInfoWidget({
    super.key,
    required this.stageNumber,
    required this.stageName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '스테이지 $stageNumber',
            style:  TextStyle(
              fontFamily: 'TJJoyofsinging',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            ': $stageName',
            style: TextStyle(
              fontFamily: 'TJJoyofsinging',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
