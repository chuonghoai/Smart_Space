import 'package:flutter/material.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

/// Chip của một chiều lọc (mở sheet chọn giá trị).
///
/// Chưa lọc: nhãn chiều lọc ("Mức độ ▾") trên nền surface, viền outlineVariant.
/// Đang lọc: hiện giá trị đã chọn ("Cao ▾") trên nền primaryContainer, không viền —
/// màu chỉ dùng để báo trạng thái đang lọc, không tô theo ngữ nghĩa của giá trị.
class ReportFilterChip extends StatelessWidget {
  /// Tên chiều lọc, vd. "Mức độ". Luôn có trong nhãn accessibility.
  final String label;

  /// Giá trị đang hiển thị trên chip; null = dùng [label].
  final String? valueLabel;

  /// Đang thu hẹp kết quả (khác mặc định) → kiểu nổi bật.
  final bool active;
  final IconData? icon;
  final VoidCallback onTap;

  const ReportFilterChip({
    super.key,
    required this.label,
    required this.onTap,
    this.valueLabel,
    this.active = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final foreground = active ? colorScheme.onPrimaryContainer : colorScheme.onSurface;
    final text = valueLabel ?? label;

    return Semantics(
      button: true,
      label: valueLabel == null ? label : l10n.filterSelectedTooltip(label, valueLabel!),
      excludeSemantics: true,
      onTap: onTap,
      child: ActionChip(
        onPressed: onTap,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: active ? colorScheme.primaryContainer : colorScheme.surface,
        side: active ? BorderSide.none : BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        avatar: icon == null ? null : Icon(icon, size: 18, color: foreground),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded, size: 20, color: foreground),
          ],
        ),
      ),
    );
  }
}
