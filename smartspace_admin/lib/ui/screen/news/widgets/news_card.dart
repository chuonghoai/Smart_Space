import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/screen/news/widgets/news_metadata_bar.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

class NewsCard extends StatefulWidget {
  final NewsModel news;

  const NewsCard({super.key, required this.news});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _cleanContentExcerpt(String content) {
    // Remove markdown symbols and normalize whitespace for clean snippet
    return content
        .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '') // images
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1') // link text
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll(RegExp(r'(\*\*|__)(.*?)\1'), r'$2') // bold
        .replaceAll(RegExp(r'(\*|_)(.*?)\1'), r'$2') // italic
        .replaceAll(RegExp(r'`{1,3}.*?`{1,3}'), '') // code
        .replaceAll(RegExp(r'>\s*'), '') // blockquote
        .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '') // lists
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final images = widget.news.imageUrls;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push(RouterPath.newsDetailWithId(widget.news.id));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hình ảnh phía trên cùng (Slider nếu nhiều ảnh)
            if (images.isNotEmpty)
              SizedBox(
                height: 220,
                width: double.infinity,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (idx) {
                        setState(() {
                          _currentImageIndex = idx;
                        });
                      },
                      itemBuilder: (context, idx) {
                        return AppNetworkImage(
                          url: images[idx],
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                    // Image indicator dots if multiple
                    if (images.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (idx) {
                            final isCurrent = idx == _currentImageIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isCurrent ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? colorScheme.primary
                                    : Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Tiêu đề
                  Text(
                    widget.news.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Metadata Bar (3 icon: người tạo, ngày tạo, giờ tạo)
                  NewsMetadataBar(
                    authorName: widget.news.authorName ?? '',
                    createdAt: widget.news.createdAt,
                    compact: true,
                  ),
                  const SizedBox(height: 12),

                  // 4. Nội dung (chỉ hiện tối đa 2 dòng đầu, phần còn lại dùng "...")
                  Text(
                    _cleanContentExcerpt(widget.news.content),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
