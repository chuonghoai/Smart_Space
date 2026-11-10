import 'package:flutter/material.dart';

/// Nút lịch 48×48 đặt cạnh ô tìm kiếm để lọc theo ngày, gọn trong một hàng trên điện thoại.
///
/// Chưa lọc: viền outlineVariant, icon xám. Đang lọc: nền primaryContainer — màu chỉ báo trạng thái
/// đang lọc, không mang nghĩa khác. [tooltip] / [semanticsValue] đã được L10n bởi app gọi.
class DateFilterIconButton extends StatelessWidget {
  final bool active;
  final String tooltip;

  /// Giá trị đang lọc để trình đọc màn hình đọc kèm (vd. "1/3 – 15/3/2026"); null khi chưa lọc.
  final String? semanticsValue;
  final VoidCallback onPressed;

  const DateFilterIconButton({
    super.key,
    required this.active,
    required this.tooltip,
    required this.onPressed,
    this.semanticsValue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: tooltip,
      value: semanticsValue,
      excludeSemantics: true,
      onTap: onPressed,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(active ? Icons.event_available_rounded : Icons.calendar_today_outlined, size: 22),
        style: IconButton.styleFrom(
          fixedSize: const Size(48, 48),
          minimumSize: const Size(48, 48),
          backgroundColor: active ? colorScheme.primaryContainer : colorScheme.surface,
          foregroundColor: active ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
          side: active ? BorderSide.none : BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
