import 'package:flutter/material.dart';

/// Dòng meta ngay trên danh sách tin: tổng số tin theo bộ lọc hiện tại (vd. "24 tin tức",
/// "3 tin tức · 1/3 – 15/3/2026") và nút chữ "Xoá lọc" bên phải khi đang lọc.
/// Mọi chuỗi đã được L10n bởi app gọi.
class NewsListMetaRow extends StatelessWidget {
  final String summary;

  /// Nhãn nút xoá lọc; null = không hiện nút (không lọc gì).
  final String? clearLabel;
  final VoidCallback? onClear;
  final EdgeInsetsGeometry padding;

  const NewsListMetaRow({
    super.key,
    required this.summary,
    this.clearLabel,
    this.onClear,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = clearLabel;

    return Padding(
      padding: padding,
      child: ConstrainedBox(
        // Giữ chiều cao cố định để danh sách không nhảy khi nút "Xoá lọc" hiện / ẩn
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            if (label != null && onClear != null) TextButton(onPressed: onClear, child: Text(label)),
          ],
        ),
      ),
    );
  }
}
