import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/features/news/application/news_providers.dart';
import 'package:smartspace_admin/features/news/data/news_repository.dart';
import 'package:smartspace_admin/features/news/models/news_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/news/utils/markdown_helpers.dart';
import 'package:smartspace_admin/ui/screen/news/widgets/news_metadata_bar.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

class AdminNewsDetailScreen extends ConsumerStatefulWidget {
  final String newsId;

  const AdminNewsDetailScreen({super.key, required this.newsId});

  @override
  ConsumerState<AdminNewsDetailScreen> createState() =>
      _AdminNewsDetailScreenState();
}

class _AdminNewsDetailScreenState extends ConsumerState<AdminNewsDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isDeleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDeleteNews(NewsModel news) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeleteNewsTitle),
        content: Text(l10n.confirmDeleteNews),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.deleteNews),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        final res = await newsRepository.deleteNews(news.id);
        if (!res.success) throw Exception(res.message);

        ref.invalidate(newsListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deleteNewsSuccess)),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final newsAsync = ref.watch(newsDetailProvider(widget.newsId));

    return AppLayout(
      child: newsAsync.when(
        data: (news) {
          final images = news.imageUrls;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Navigation & Actions Header
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.newsDetail,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_isDeleting)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            tooltip: l10n.editNews,
                            onSelected: (value) {
                              if (value == 'edit') {
                                context.push(RouterPath.editNewsWithId(news.id));
                              } else if (value == 'delete') {
                                _confirmAndDeleteNews(news);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(l10n.editNews),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: colorScheme.error,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      l10n.deleteNews,
                                      style: TextStyle(color: colorScheme.error),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // QUY TẮC HIỂN THỊ:
                    // 1. TIÊU ĐỀ
                    Text(
                      news.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. METADATA (người tạo, ngày tạo, giờ tạo với 3 icon riêng biệt)
                    NewsMetadataBar(
                      authorName: news.authorName ?? 'Admin',
                      createdAt: news.createdAt,
                      compact: false,
                    ),
                    const SizedBox(height: 20),

                    // 3. HÌNH ẢNH (Slider / Viewer)
                    if (images.isNotEmpty) ...[
                      Container(
                        height: 380,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
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
                                  height: 380,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                            if (images.length > 1)
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(images.length, (idx) {
                                    final isCurrent = idx == _currentImageIndex;
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      width: isCurrent ? 22 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? colorScheme.primary
                                            : Colors.white.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 4. CONTENT (Readme view / Markdown view)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surface
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.4),
                        ),
                      ),
                      child: MarkdownBody(
                        data: formatMarkdownPreservingNewlines(news.content),
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: colorScheme.onSurface,
                          ),
                          h1: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          h2: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          h3: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: colorScheme.primary,
                                width: 4,
                              ),
                            ),
                          ),
                          code: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            backgroundColor:
                                colorScheme.surfaceVariant.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 12),
                Text(err.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(newsDetailProvider(widget.newsId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
