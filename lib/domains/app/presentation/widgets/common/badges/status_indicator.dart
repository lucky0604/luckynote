import 'package:flutter/material.dart';

/// Status types for the status indicator.
enum StatusType {
  info,
  success,
  warning,
  error,
  loading,
}

/// A status indicator component for displaying status states.
///
/// Commonly used for showing connection status, sync status, etc.
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    super.key,
    required this.status,
    this.label,
    this.size = 8,
    this.useIcon = false,
  });

  final StatusType status;
  final String? label;
  final double size;
  final bool useIcon;

  Color _getColor(BuildContext context) {
    switch (status) {
      case StatusType.info:
        return Theme.of(context).colorScheme.primary;
      case StatusType.success:
        return Colors.green;
      case StatusType.warning:
        return Colors.orange;
      case StatusType.error:
        return Colors.red;
      case StatusType.loading:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case StatusType.info:
        return Icons.info_outline;
      case StatusType.success:
        return Icons.check_circle_outline;
      case StatusType.warning:
        return Icons.warning_amber_outlined;
      case StatusType.error:
        return Icons.error_outline;
      case StatusType.loading:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);

    if (useIcon) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: size + 4,
            color: color,
          ),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label!,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );
    }

    if (status == StatusType.loading) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 6),
          Text(
            label!,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
