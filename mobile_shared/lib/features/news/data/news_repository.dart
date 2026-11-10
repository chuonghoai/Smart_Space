import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import '../models/news_model.dart';
import '../models/news_page.dart';

class NewsRepository {
  /// Tin tức mới nhất trước, phân trang ([page] bắt đầu từ 1).
  /// [search] tìm trong tiêu đề / nội dung; [from] / [to] lọc theo ngày tạo (cả 2 đầu đều bao gồm).
  Future<ApiResponse<NewsPage>> getNews({
    int page = 1,
    int size = 10,
    String? search,
    DateTime? from,
    DateTime? to,
  }) {
    final keyword = search?.trim();
    return apiClient.get(
      '/news',
      queryParameters: {
        'page': page,
        'size': size,
        if (keyword != null && keyword.isNotEmpty) 'search': keyword,
        if (from != null) 'from': _isoDate(from),
        if (to != null) 'to': _isoDate(to),
      },
      decoder: NewsPage.fromJson,
    );
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<ApiResponse<NewsModel>> getNewsDetail(String id) {
    return apiClient.get(
      '/news/$id',
      decoder: (json) => NewsModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<NewsModel>> createNews({
    required String title,
    required String content,
    List<String>? imageUrls,
    bool? sendNotification,
    List<String>? targetRoles,
  }) {
    return apiClient.post(
      '/news',
      data: {
        'title': title,
        'content': content,
        'image_urls': imageUrls ?? [],
        if (sendNotification != null) 'send_notification': sendNotification,
        if (targetRoles != null) 'target_roles': targetRoles,
      },
      decoder: (json) => NewsModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<NewsModel>> updateNews({
    required String id,
    required String title,
    required String content,
    List<String>? imageUrls,
  }) {
    return apiClient.put(
      '/news/$id',
      data: {
        'title': title,
        'content': content,
        'image_urls': imageUrls ?? [],
      },
      decoder: (json) => NewsModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> deleteNews(String id) {
    return apiClient.delete('/news/$id');
  }
}

final newsRepository = NewsRepository();
