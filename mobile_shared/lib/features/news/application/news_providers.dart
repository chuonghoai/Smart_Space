import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/news_repository.dart';
import '../models/news_model.dart';

final newsListProvider =
    FutureProvider.autoDispose<List<NewsModel>>((ref) async {
  final res = await newsRepository.getAllNews();
  if (res.success && res.data != null) {
    return res.data!;
  }
  throw Exception(res.message);
});

final newsDetailProvider =
    FutureProvider.autoDispose.family<NewsModel, String>((ref, id) async {
  final res = await newsRepository.getNewsDetail(id);
  if (res.success && res.data != null) {
    return res.data!;
  }
  throw Exception(res.message);
});

final latestNewsProvider =
    FutureProvider.autoDispose<List<NewsModel>>((ref) async {
  final newsList = await ref.watch(newsListProvider.future);
  return newsList.take(5).toList();
});
