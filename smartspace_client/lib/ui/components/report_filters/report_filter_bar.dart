import 'package:flutter/material.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

/// Thanh lọc danh sách phản ánh (Bảng tin, Phản ánh của tôi), tối đa 2 hàng điều khiển trên điện thoại:
///   1. ô tìm kiếm;
///   2. một hàng chip lọc cuộn ngang ([chips]) + "Xoá lọc" khi đang lọc;
/// và dòng "N kết quả" khi đang lọc để số đếm đi theo đúng khung nhìn hiện tại.
class ReportFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final List<Widget> chips;

  /// Đang lọc/tìm → hiện "Xoá lọc" và [resultCount].
  final bool isFiltering;

  /// Xoá mọi bộ lọc. Ô tìm kiếm được xoá ở đây trước khi gọi.
  final VoidCallback onClearFilters;

  /// Tổng số kết quả của bộ lọc hiện tại; null = đang tải (ẩn dòng đếm).
  final int? resultCount;

  /// Lề ngang của nội dung; hàng chip cuộn tràn tới mép màn hình.
  final double horizontalPadding;

  const ReportFilterBar({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.onSearchChanged,
    required this.chips,
    required this.isFiltering,
    required this.onClearFilters,
    this.resultCount,
    this.horizontalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: searchController,
            builder: (context, value, _) => TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyLarge,
              // Màu nền, viền, bo góc và focus lấy từ InputDecorationTheme của app
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: colorScheme.onSurfaceVariant,
                        tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                chips[i],
              ],
              if (isFiltering) ...[
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () {
                    searchController.clear();
                    onClearFilters();
                  },
                  child: Text(l10n.clearFilters),
                ),
              ],
            ],
          ),
        ),
        if (isFiltering && resultCount != null)
          Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 0),
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.resultsCount(resultCount!),
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }
}
