import 'news_model.dart';

/// Một trang tin tức từ `GET /news` (PageResponse của backend, [currentPage] bắt đầu từ 1).
class NewsPage {
  final List<NewsModel> items;
  final int currentPage;
  final int totalPages;
  final int totalElements;

  const NewsPage({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
  });

  bool get hasMore => currentPage < totalPages;

  factory NewsPage.fromJson(dynamic json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final content = map['content'];
    return NewsPage(
      items: content is List
          ? content.whereType<Map<String, dynamic>>().map(NewsModel.fromJson).toList()
          : const <NewsModel>[],
      currentPage: (map['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? 0,
      totalElements: (map['totalElements'] as num?)?.toInt() ?? 0,
    );
  }
}
