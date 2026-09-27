import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/auth/user_storage_service.dart';
import 'package:mobile_shared/mobile_shared.dart';

class HomeState {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  HomeState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  HomeState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  final Ref ref;

  HomeController(this.ref) : super(HomeState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final user = await userStorageService.getUser();
    state = state.copyWith(user: user, isLoading: false);
  }

  Future<void> manualRefresh() async {
    state = state.copyWith(isLoading: true);
    final user = await userStorageService.getUser();
    state = state.copyWith(user: user, isLoading: false);
  }
}

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) {
    return HomeController(ref);
  },
);
