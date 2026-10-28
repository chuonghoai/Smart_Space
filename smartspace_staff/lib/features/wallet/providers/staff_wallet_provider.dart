import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_model.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_transaction_model.dart';
import 'package:smartspace_staff/features/wallet/services/staff_wallet_service.dart';

class StaffWalletState {
  final bool isLoading;
  final StaffWalletModel? wallet;
  final String? error;

  StaffWalletState({
    this.isLoading = false,
    this.wallet,
    this.error,
  });

  StaffWalletState copyWith({
    bool? isLoading,
    StaffWalletModel? wallet,
    String? error,
  }) {
    return StaffWalletState(
      isLoading: isLoading ?? this.isLoading,
      wallet: wallet ?? this.wallet,
      error: error,
    );
  }
}

class StaffWalletNotifier extends StateNotifier<StaffWalletState> {
  StaffWalletNotifier() : super(StaffWalletState()) {
    loadWallet();
  }

  Future<void> loadWallet({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final res = await staffWalletService.getWallet();
      if (res.success && res.data != null) {
        state = state.copyWith(wallet: res.data, isLoading: false, error: null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.message,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadWallet(silent: true);
}

final staffWalletProvider =
    StateNotifierProvider<StaffWalletNotifier, StaffWalletState>((ref) {
  return StaffWalletNotifier();
});

class StaffTransactionsState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<StaffWalletTransactionModel> transactions;
  final bool hasMore;
  final int page;
  final String? error;

  StaffTransactionsState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.transactions = const [],
    this.hasMore = true,
    this.page = 0,
    this.error,
  });

  StaffTransactionsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<StaffWalletTransactionModel>? transactions,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return StaffTransactionsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
    );
  }
}

class StaffTransactionsNotifier extends StateNotifier<StaffTransactionsState> {
  StaffTransactionsNotifier() : super(StaffTransactionsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null, page: 0, hasMore: true);
    try {
      final res = await staffWalletService.getTransactions(page: 0, size: 20);
      if (res.success && res.data != null) {
        final items = res.data!;
        state = state.copyWith(
          transactions: items,
          hasMore: items.length >= 20,
          page: 0,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.message,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final res = await staffWalletService.getTransactions(page: nextPage, size: 20);
      if (res.success && res.data != null) {
        final newItems = res.data!;
        state = state.copyWith(
          transactions: [...state.transactions, ...newItems],
          hasMore: newItems.length >= 20,
          page: nextPage,
          isLoadingMore: false,
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() => loadInitial();
}

final staffTransactionsProvider =
    StateNotifierProvider<StaffTransactionsNotifier, StaffTransactionsState>(
        (ref) {
  return StaffTransactionsNotifier();
});
