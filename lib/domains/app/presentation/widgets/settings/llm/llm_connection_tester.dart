import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Connection test result widget.
///
/// Shows the status of the last connection test.
class ConnectionTestResult extends StatelessWidget {
  const ConnectionTestResult({
    super.key,
    required this.result,
  });

  final bool result;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          result ? LucideIcons.checkCircle : LucideIcons.xCircle,
          size: 16,
          color: result ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 6),
        Text(
          result ? '连接正常' : '连接失败',
          style: TextStyle(
            color: result ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Connection tester button.
///
/// Shows the test button with loading state.
class ConnectionTestButton extends StatelessWidget {
  const ConnectionTestButton({
    super.key,
    required this.isTesting,
    required this.onPressed,
  });

  final bool isTesting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: isTesting ? null : onPressed,
        icon: isTesting
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(LucideIcons.wifi, size: 16),
        label: Text(isTesting ? '测试中...' : '测试连接'),
      ),
    );
  }
}
