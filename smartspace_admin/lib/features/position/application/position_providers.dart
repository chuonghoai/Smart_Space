import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/position_repository.dart';
import '../models/position_model.dart';

/// Toàn bộ chức vụ (gồm cả ngừng hoạt động) — dùng cho màn quản lý.
final positionListProvider =
    FutureProvider.autoDispose<List<PositionModel>>((ref) async {
  final res = await positionRepository.getPositions();
  if (res.success && res.data != null) return res.data!;
  throw Exception(res.message);
});

/// Chỉ chức vụ đang hoạt động — dùng cho dropdown gán / lọc staff.
final activePositionsProvider =
    FutureProvider.autoDispose<List<PositionModel>>((ref) async {
  final res = await positionRepository.getPositions(activeOnly: true);
  if (res.success && res.data != null) return res.data!;
  return [];
});
