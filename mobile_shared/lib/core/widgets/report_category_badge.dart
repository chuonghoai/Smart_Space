import 'package:flutter/material.dart';

import '../utils/report_category_helper.dart';

/// Badge hiển thị danh mục của phản ánh, dùng chung giữa các app.
///
/// Màu lấy từ `secondaryContainer` / `onSecondaryContainer` của theme hiện hành
/// nên tương phản đúng ở cả Light Mode và Dark Mode.
class ReportCategoryBadge extends StatelessWidget {
  final String label;
  final String? iconKey;

  const ReportCategoryBadge({super.key, required this.label, this.iconKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ReportCategoryHelper.iconFor(iconKey),
            size: 14,
            color: cs.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
