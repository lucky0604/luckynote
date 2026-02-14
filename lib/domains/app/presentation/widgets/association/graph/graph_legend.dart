import 'package:flutter/widgets.dart';

import 'package:luckynote/app/theme/app_colors.dart';

/// Legend widget for graph visualization.
///
/// Shows what each node color represents.
class GraphLegend extends StatelessWidget {
  const GraphLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem('当前', AppColors.accent),
        const SizedBox(width: 8),
        _buildLegendItem('引用', AppColors.linkColor),
        const SizedBox(width: 8),
        _buildLegendItem('被引用', AppColors.success),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
