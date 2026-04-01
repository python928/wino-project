import 'package:flutter/material.dart';

class WinoCoinBadge extends StatelessWidget {
  final int coins;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const WinoCoinBadge({
    super.key,
    required this.coins,
    this.onTap,
    this.margin = const EdgeInsetsDirectional.only(end: 10),
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 34,
      padding: const EdgeInsetsDirectional.only(start: 6, end: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBED5FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFF1F6FFF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'W',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: Color(0xFF1249A6),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    final child = Padding(padding: margin, child: content);
    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}