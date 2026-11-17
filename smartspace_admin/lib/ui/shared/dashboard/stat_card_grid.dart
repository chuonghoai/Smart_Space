import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lưới thẻ thống kê có chiều cao cố định.
///
/// Khi hàng cuối chỉ còn đúng 1 thẻ (và lưới có từ 2 cột), thẻ đó được giãn
/// thành 2 ô để không bị đứng lẻ loi.
///
/// [itemBuilder] nhận cờ `spanned` để thẻ bị giãn căn giữa nội dung, tránh
/// icon + chữ dồn hết sang trái của một ô rộng gấp đôi.
///
/// Dùng `Row` + chiều rộng tính sẵn thay vì `Wrap`: `Wrap` không có dung sai
/// làm tròn nên ô cuối dễ bị đẩy xuống dòng do sai số dấu phẩy động.
class StatCardGrid extends StatelessWidget {
  final int crossAxisCount;
  final double itemHeight;
  final double spacing;
  final int itemCount;
  final Widget Function(BuildContext context, int index, bool spanned)
      itemBuilder;

  const StatCardGrid({
    super.key,
    required this.crossAxisCount,
    required this.itemHeight,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) return const SizedBox.shrink();
    final cols = math.max(1, crossAxisCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final cellWidth = (maxWidth - spacing * (cols - 1)) / cols;
        final hasOrphan = cols >= 2 && itemCount % cols == 1;

        final rows = <Widget>[];
        for (var start = 0; start < itemCount; start += cols) {
          final end = math.min(start + cols, itemCount);
          final cells = <Widget>[];
          for (var i = start; i < end; i++) {
            final spanned = hasOrphan && i == itemCount - 1;
            final span = spanned ? 2 : 1;
            if (i > start) cells.add(SizedBox(width: spacing));
            cells.add(
              SizedBox(
                width: cellWidth * span + spacing * (span - 1),
                height: itemHeight,
                child: itemBuilder(context, i, spanned),
              ),
            );
          }
          if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
          rows.add(Row(children: cells));
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        );
      },
    );
  }
}
