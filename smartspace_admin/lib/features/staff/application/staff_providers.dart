import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/staff_repository.dart';
import '../models/staff_chart_model.dart';
import '../models/staff_list_response.dart';

class StaffListNotifier extends AutoDisposeAsyncNotifier<StaffListResponse> {
  int _currentPage = 1;
  final int _pageSize = 10;
  String? _search;
  String? _statusFilter;
  Timer? _debounce;

  @override
  Future<StaffListResponse> build() async {
    ref.onDispose(() => _debounce?.cancel());
    return _fetch();
  }

  Future<StaffListResponse> _fetch() async {
    final response = await staffRepository.getStaffs(
      page: _currentPage,
      size: _pageSize,
      search: _search,
      status: _statusFilter,
    );
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.message);
  }

  // Update Status
  Future<bool> toggleStaffStatus(String staffId, bool isCurrentlyActive) async {
    final newStatus = isCurrentlyActive ? 'blocked' : 'active';
    final response = await staffRepository.updateStaffStatus(
      staffId,
      newStatus,
    );
    if (response.success) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }

  // Create Staff
  Future<bool> createStaff({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? avatarUrl,
  }) async {
    final response = await staffRepository.createStaff(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
      dateOfBirth: dateOfBirth,
      gender: gender,
      avatarUrl: avatarUrl,
    );
    if (response.success) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }

  // Update Staff
  Future<bool> updateStaff({
    required String staffId,
    required String fullName,
    required String email,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? avatarUrl,
  }) async {
    final response = await staffRepository.updateStaff(
      staffId: staffId,
      fullName: fullName,
      email: email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      gender: gender,
      avatarUrl: avatarUrl,
    );
    if (response.success) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }

  Future<void> refresh() async {
    _currentPage = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  void setSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search = query.isEmpty ? null : query;
      _currentPage = 1;
      ref.invalidateSelf();
    });
  }

  void setStatusFilter(String? status) {
    _statusFilter = (status == null || status == 'all') ? null : status;
    _currentPage = 1;
    ref.invalidateSelf();
  }

  void goToPage(int page) {
    _currentPage = page;
    ref.invalidateSelf();
  }

  void nextPage() {
    final data = state.valueOrNull;
    if (data != null && _currentPage < data.totalPages) {
      goToPage(_currentPage + 1);
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      goToPage(_currentPage - 1);
    }
  }
}

final staffListProvider =
    AutoDisposeAsyncNotifierProvider<StaffListNotifier, StaffListResponse>(
      () => StaffListNotifier(),
    );

final staffChartProvider = FutureProvider.autoDispose<StaffChartModel>((
  ref,
) async {
  return staffRepository.getChartData();
});
