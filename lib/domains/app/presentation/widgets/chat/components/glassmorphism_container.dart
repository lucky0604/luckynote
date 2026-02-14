import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:luckynote/app/theme/app_colors.dart';

/// 毛玻璃效果容器
class GlassmorphismContainer extends StatelessWidget {
  const GlassmorphismContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.85,
    this.borderRadius = 16,
    this.border,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: blur * 2,
                offset: const Offset(-10, 0),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
