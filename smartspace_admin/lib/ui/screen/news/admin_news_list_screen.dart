import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/features/news/application/news_providers.dart';
import 'package:smartspace_admin/features/news/models/news_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/news/widgets/news_metadata_bar.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

class AdminNewsListScreen extends ConsumerWidget {
  const AdminNewsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final newsAsync = ref.watch(newsListProvider);

    return AppLayout(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouterPath.createNews),
        icon: const Icon(Icons.add),
        label: Text(l10n.createNewNews),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(newsListProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.manageNews,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.push(RouterPath.createNews),
                      icon: const Icon(Icons.post_add, size: 18),
                      label: Text(l10n.createNewNews),
                    ),
                  ],
                ),
              ),
            ),
            newsAsync.when(
              data: (newsList) {
                if (newsList.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context, l10n, theme, colorScheme),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final news = newsList[index];
                        return _NewsCard(news: news);
                      },
                      childCount: newsList.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => ref.invalidate(newsListProvider),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.newspaper_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.emptyNewsTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                l10n.emptyNewsDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(RouterPath.createNews),
              icon: const Icon(Icons.add),
              label: Text(l10n.createNewNews),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatefulWidget {
  final NewsModel news;

  const _NewsCard({required this.news});

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _cleanContentExcerpt(String content) {
    // Remove markdown symbols for clean snippet
    String text = content
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll(RegExp(r'\*\*|\*|__|`|>|\-'), '')
        .trim();
    if (text.length > 150) {
      return '${text.substring(0, 150)}...';
    }
    return text;
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
          color: colorScheme.outlineVariant.withOpacity(0.5),
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
                                    : Colors.white.withOpacity(0.6),
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
                    authorName: widget.news.authorName ?? 'Admin',
                    createdAt: widget.news.createdAt,
                    compact: true,
                  ),
                  const SizedBox(height: 12),

                  // 4. 1 phần đầu của content (cắt ngắn, dùng "...")
                  Text(
                    _cleanContentExcerpt(widget.news.content),
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
