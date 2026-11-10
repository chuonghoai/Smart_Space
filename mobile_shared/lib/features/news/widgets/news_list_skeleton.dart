import 'package:flutter/material.dart';

/// Khung chờ của danh sách tin tức: các thẻ cùng kích thước `NewsCard` với khối xám phẳng thay cho nội dung
/// (không shimmer), để bố cục không nhảy khi dữ liệu về.
class NewsListSkeleton extends StatelessWidget {
  /// Nhãn đọc cho trình đọc màn hình (đã L10n bởi app gọi), vd. "đang tải...".
  final String semanticsLabel;
  final int count;
  final EdgeInsetsGeometry padding;

  const NewsListSkeleton({
    super.key,
    required this.semanticsLabel,
    this.count = 3,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          itemCount: count,
          // Thẻ đầu có ảnh, các thẻ sau không: giống tỉ lệ tin có / không có ảnh thường gặp
          itemBuilder: (context, index) => NewsCardSkeleton(withImage: index == 0),
        ),
      ),
    );
  }
}

/// Một thẻ chờ cùng kích thước `NewsCard`; [withImage] = có khối ảnh 200px ở trên.
class NewsCardSkeleton extends StatelessWidget {
  final bool withImage;

  const NewsCardSkeleton({super.key, this.withImage = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final block = colorScheme.surfaceContainerHighest;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (withImage) Container(height: 200, color: block),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(block, widthFactor: 0.7, height: 20),
                const SizedBox(height: 12),
                _bar(block, widthFactor: 0.4, height: 14),
                const SizedBox(height: 12),
                _bar(block, widthFactor: 1, height: 14),
                const SizedBox(height: 6),
                _bar(block, widthFactor: 0.6, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(Color color, {required double widthFactor, required double height}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
