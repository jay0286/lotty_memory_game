import 'package:flutter/material.dart';

/// Flutter OSD widget for displaying hint count
class HintCountWidget extends StatelessWidget {
  final ValueNotifier<int> hintNotifier;

  const HintCountWidget({
    super.key,
    required this.hintNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: hintNotifier,
      builder: (context, hints, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(32),
            // border: Border.all(
            //   color: const Color(0xFFFFC107),
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
                'assets/images/hint_icon.png',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'X $hints',
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
