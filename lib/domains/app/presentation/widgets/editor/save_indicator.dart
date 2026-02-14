import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luckynote/app/theme/app_colors.dart';

/// 保存状态指示器
/// 显示保存状态，并在保存完成后显示短暂的"已保存"动画
class SaveIndicator extends StatefulWidget {
  const SaveIndicator({
    super.key,
    required this.isDirty,
    required this.isSaving,
    required this.onSave,
  });

  final bool isDirty;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  State<SaveIndicator> createState() => _SaveIndicatorState();
}

class _SaveIndicatorState extends State<SaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _showJustSaved = false;
  bool _wasSaving = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_animationController);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(SaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect save completion: was saving -> not saving, and not dirty
    if (_wasSaving && !widget.isSaving && !widget.isDirty) {
      _showSavedAnimation();
    }

    _wasSaving = widget.isSaving;
  }

  void _showSavedAnimation() {
    setState(() => _showJustSaved = true);
    _animationController.forward(from: 0.0);

    // Hide after animation + display time
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showJustSaved = false);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSaving) {
      return _buildSavingIndicator();
    }

    if (_showJustSaved) {
      return _buildJustSavedIndicator();
    }

    if (!widget.isDirty) {
      return _buildSavedIndicator();
    }

    return _buildSaveButton();
  }

  Widget _buildSavingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '保存中...',
          style: TextStyle(fontSize: 12, color: AppColors.textPlaceholder),
        ),
      ],
    );
  }

  Widget _buildJustSavedIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    '已保存',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.check, size: 14, color: AppColors.success),
        const SizedBox(width: 4),
        Text(
          '已保存',
          style: TextStyle(fontSize: 12, color: AppColors.textPlaceholder),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onSave,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.save, size: 14, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                '保存',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
