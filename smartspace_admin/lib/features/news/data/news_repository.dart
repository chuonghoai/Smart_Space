import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import '../models/news_model.dart';

class NewsRepository {
  Future<ApiResponse<List<NewsModel>>> getAllNews() {
    return apiClient.get(
      '/news',
      decoder: (json) {
        if (json is List) {
          return json
              .map((e) => NewsModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <NewsModel>[];
      },
    );
  }

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

  Future<ApiResponse> deleteNews(String id) {
    return apiClient.delete('/news/$id');
  }
}

final newsRepository = NewsRepository();
