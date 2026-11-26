import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/category_repository.dart';
import '../models/category_model.dart';

final categoryListProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final res = await categoryRepository.getCategories();
  if (res.success && res.data != null) return res.data!;
  throw Exception(res.message);
});

final activeCategoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final res = await categoryRepository.getCategories(activeOnly: true);
  if (res.success && res.data != null) return res.data!;
  return [];
});
