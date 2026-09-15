import 'package:flutter/material.dart';
import 'package:tents/ui/core/theme/app_colors.dart';

class TreeWidget extends StatelessWidget {
  const TreeWidget({
    super.key,
    required this.size,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/tree.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class TentWidget extends StatelessWidget {
  const TentWidget({
    super.key,
    required this.size,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isConflict = color == const Color(0xFFFF5252);
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/tent.png',
        fit: BoxFit.contain,
        color: isConflict ? color : null,
        colorBlendMode: isConflict ? BlendMode.srcIn : null,
      ),
    );
  }
}

class CrossWidget extends StatelessWidget {
  const CrossWidget({
    super.key,
    required this.size,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.close_rounded,
      size: size * 0.7,
      color: color ?? AppColors.subtext,
    );
  }
}
