import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

class ClientNewsDetailScreen extends StatefulWidget {
  final String newsId;

  const ClientNewsDetailScreen({super.key, required this.newsId});

  @override
  State<ClientNewsDetailScreen> createState() => _ClientNewsDetailScreenState();
}

class _ClientNewsDetailScreenState extends State<ClientNewsDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  NewsModel? _news;

  @override
  void initState() {
    super.initState();
    _fetchNewsDetail();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchNewsDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await newsRepository.getNewsDetail(widget.newsId);
      if (res.success && res.data != null) {
        if (mounted) {
          setState(() {
            _news = res.data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = res.message.isNotEmpty ? res.message : 'Error';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openFullscreenImage(List<String> images, int initialIndex) {
    if (images.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(
          imageUrls: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.newsDetail),
        centerTitle: false,
      ),
      body: _buildBody(context, l10n, theme, colorScheme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _news == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? l10n.newsNotFound,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _fetchNewsDetail,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final news = _news!;
    final images = news.imageUrls;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image slider
          if (images.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final imgUrl = images[index];
                        return GestureDetector(
                          onTap: () => _openFullscreenImage(images, index),
                          child: Hero(
                            tag: 'news_img_${news.id}_$index',
                            child: Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 48,
                                  color: colorScheme.outline,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentImageIndex == index ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. Title
          Text(
            news.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),

          // 3. Metadata Bar (Author bold, Date & Time italic & smaller font)
          _buildMetadataBar(news, l10n, theme, colorScheme),
          const SizedBox(height: 16),

          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 16),

          // 4. Content (rendered directly on default background)
          MarkdownBody(
            data: news.content,
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
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMetadataBar(
    NewsModel news,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final effectiveAuthor =
        (news.authorName != null && news.authorName!.trim().isNotEmpty)
            ? news.authorName!.trim()
            : l10n.targetAdmin;

    final dateStr = news.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(news.createdAt!)
        : '--/--/----';
    final timeStr = news.createdAt != null
        ? DateFormat('HH:mm').format(news.createdAt!)
        : '--:--';

    const double fontSize = 13.0;
    const double iconSize = 15.0;
    final iconColor = colorScheme.primary;
    final secondaryColor = colorScheme.onSurfaceVariant;

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded,
                size: iconSize, color: iconColor),
            const SizedBox(width: 5),
            Text(
              effectiveAuthor,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: iconSize, color: iconColor),
            const SizedBox(width: 5),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.italic,
                color: secondaryColor,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_rounded, size: iconSize, color: iconColor),
            const SizedBox(width: 5),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.italic,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
