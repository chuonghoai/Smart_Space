import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/account_lock/application/account_lock_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/admin_board/lock_requests/lock_request_widgets.dart';

/// Tab "Đề xuất khoá" — câu hỏi của màn: "Đề xuất nào cần tôi bỏ phiếu, và còn bao lâu?".
/// Thứ tự đọc: tiêu đề + finding → thẻ đếm (bộ lọc) → danh sách (hạn gần nhất trước) → chi tiết.
class LockRequestsTab extends ConsumerStatefulWidget {
  /// Mở sẵn một đề xuất (vd: khi bấm vào thông báo).
  final String? initialRequestId;

  const LockRequestsTab({super.key, this.initialRequestId});

  @override
  ConsumerState<LockRequestsTab> createState() => _LockRequestsTabState();
}

class _LockRequestsTabState extends ConsumerState<LockRequestsTab> {
  static const double _sidePanelBreakpoint = 1000;
  static const double _sidePanelWidth = 440;
  static const double _phoneBreakpoint = 640;
  static const double _loadMoreThreshold = 300;

  final _scrollController = ScrollController();

  /// Mặc định "Cần bạn"; nếu không còn gì cần bạn và người dùng chưa tự chọn → chuyển sang "Đang chờ".
  LockRequestFilter _filter = LockRequestFilter.awaitingMine;
  bool _filterTouched = false;
  String? _selectedId;
  bool _isWide = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
    final initialId = widget.initialRequestId;
    if (initialId != null && initialId.isNotEmpty) {
      _filterTouched = true; // mở từ thông báo: không tự đổi bộ lọc dưới tay người dùng
      _filter = LockRequestFilter.pending;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_isWide) {
          setState(() => _selectedId = initialId);
        } else {
          showLockRequestDetail(context, initialId);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_maybeLoadMore)
      ..dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < _loadMoreThreshold) {
      ref.read(lockRequestListProvider(_filter).notifier).loadMore();
    }
  }

  void _setFilter(LockRequestFilter filter) {
    if (filter == _filter) return;
    setState(() {
      _filter = filter;
      _filterTouched = true;
      _selectedId = null;
    });
  }

  void _open(String id) {
    if (_isWide) {
      setState(() => _selectedId = id);
    } else {
      showLockRequestDetail(context, id);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(lockPendingCountProvider);
    await ref.read(lockRequestListProvider(_filter).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    ref.listen(lockRequestListProvider(_filter), (_, next) {
      // Trang đầu chưa lấp đầy khung → không có scroll để kích hoạt tải thêm
      if (next.hasValue && !next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeLoadMore();
        });
      }
    });
    ref.listen(lockPendingCountProvider, (_, next) {
      final count = next.valueOrNull;
      if (!_filterTouched && count != null && count.awaitingMyVote == 0 && count.pending > 0) {
        setState(() => _filter = LockRequestFilter.pending);
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        _isWide = constraints.maxWidth >= _sidePanelBreakpoint;
        final isPhone = constraints.maxWidth < _phoneBreakpoint;
        final gutter = isPhone ? 16.0 : 24.0;

        final main = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onRefresh: _refresh, filter: _filter, compact: isPhone),
            SizedBox(height: isPhone ? 12 : 16),
            isPhone
                ? _FilterChips(selected: _filter, onSelected: _setFilter)
                : _CountCards(selected: _filter, onSelected: _setFilter),
            const SizedBox(height: 16),
            Expanded(child: _buildList(l10n, theme)),
          ],
        );

        return Padding(
          padding: EdgeInsets.fromLTRB(gutter, gutter, gutter, 0),
          child: !_isWide
              ? main
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: main),
                    const SizedBox(width: 24),
                    SizedBox(width: _sidePanelWidth, child: _buildSidePanel(l10n, theme)),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildList(AppLocalizations l10n, ThemeData theme) {
    final cs = theme.colorScheme;
    final provider = lockRequestListProvider(_filter);
    final listAsync = ref.watch(provider);

    // Danh sách là MỘT panel kẻ dòng (không phải nhiều card có viền). Panel co theo nội dung và chỉ
    // cuộn khi dài hơn khung → không để lại khoảng trắng bị kéo giãn dưới vài dòng.
    Widget frame(Widget child) => Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: child,
          ),
        );

    return RefreshIndicator(
      onRefresh: _refresh,
      child: listAsync.when(
        loading: () => frame(
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, _) => Divider(height: 1, indent: 68, color: theme.dividerColor),
            itemBuilder: (_, _) => const LockRequestRowSkeleton(),
          ),
        ),
        error: (error, _) => frame(
          ListView(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error.toString().replaceFirst('Exception: ', ''))),
                  TextButton(onPressed: () => ref.invalidate(provider), child: Text(l10n.retry)),
                ],
              ),
            ],
          ),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            // Trống: giữ khung, một câu
            return frame(
              SizedBox(
                width: double.infinity,
                child: ListView(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
                    Text(
                      switch (_filter) {
                        LockRequestFilter.awaitingMine => l10n.noAwaitingLockRequests,
                        LockRequestFilter.pending => l10n.noPendingLockRequests,
                        LockRequestFilter.resolved => l10n.noResolvedLockRequests,
                      },
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }
          return frame(
            ListView.separated(
              shrinkWrap: true,
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: data.items.length + 1, // +1: footer
              separatorBuilder: (_, index) => index >= data.items.length - 1
                  ? const SizedBox.shrink()
                  : Divider(height: 1, indent: 68, color: theme.dividerColor),
              itemBuilder: (context, index) {
                if (index == data.items.length) return _buildFooter(l10n, theme, data);
                final item = data.items[index];
                return LockRequestRow(
                  request: item,
                  selected: _isWide && item.id == _selectedId,
                  showAwaitingMarker: _filter != LockRequestFilter.awaitingMine,
                  onTap: () => _open(item.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n, ThemeData theme, LockRequestListState data) {
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final Widget child;
    if (data.isLoadingMore) {
      child = const LockRequestRowSkeleton();
    } else if (data.loadMoreFailed) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.loadMoreLockRequestsFailed, style: muted),
          TextButton(
            onPressed: () => ref.read(lockRequestListProvider(_filter).notifier).loadMore(retry: true),
            child: Text(l10n.retry),
          ),
        ],
      );
    } else if (!data.hasMore) {
      child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text(l10n.allLockRequestsLoaded, style: muted)),
      );
    } else {
      child = const SizedBox(height: 24);
    }
    return Column(children: [Divider(height: 1, color: theme.dividerColor), child]);
  }

  Widget _buildSidePanel(AppLocalizations l10n, ThemeData theme) {
    final selectedId = _selectedId;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: selectedId == null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.selectLockRequestHint,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: LockRequestDetailPanel(key: ValueKey(selectedId), requestId: selectedId),
            ),
    );
  }
}

/// Tiêu đề + finding (câu trả lời cho câu hỏi của màn) + mốc cập nhật và nút làm mới.
class _Header extends ConsumerWidget {
  final Future<void> Function() onRefresh;
  final LockRequestFilter filter;

  /// Điện thoại: ẩn mốc "Cập nhật lúc" (giữ nút làm mới), finding được xuống 2 dòng.
  final bool compact;

  const _Header({required this.onRefresh, required this.filter, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final count = ref.watch(lockPendingCountProvider).valueOrNull;
    final fetchedAt = ref.watch(lockRequestListProvider(filter)).valueOrNull?.fetchedAt;

    // Finding màu mực khi có việc cần làm, xám khi không; KHÔNG tô đỏ — tín hiệu đỏ đã nằm trên
    // chính dòng và đồng hồ của đề xuất sắp hết hạn (đỏ là tín hiệu, không phải texture).
    String? finding;
    var actionable = false;
    if (count != null) {
      if (count.awaitingMyVote > 0) {
        finding = l10n.lockFindingAwaiting(count.awaitingMyVote, lockTimeLeft(l10n, count.nextDeadlineAt));
        actionable = true;
      } else if (count.pending > 0) {
        finding = l10n.lockFindingOthers(count.pending);
      } else {
        finding = l10n.noPendingLockRequests;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.lockRequestsTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              // Giữ chỗ tối thiểu một dòng khi chưa có số liệu → bố cục không nhảy
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 20),
                child: finding == null
                    ? null
                    : Text(
                        finding,
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: actionable ? cs.onSurface : cs.onSurfaceVariant,
                          fontWeight: actionable ? FontWeight.w500 : null,
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (fetchedAt != null && !compact)
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 4),
            child: Text(
              l10n.lockUpdatedAt(DateFormat('HH:mm').format(fetchedAt)),
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        IconButton(tooltip: l10n.lockRefresh, icon: const Icon(Icons.refresh), onPressed: onRefresh),
      ],
    );
  }
}

/// Ba thẻ đếm ngang hàng cũng là bộ lọc: nhãn xám 13px trên số 16/600; thẻ chọn viền 1.5px primary.
class _CountCards extends ConsumerWidget {
  final LockRequestFilter selected;
  final ValueChanged<LockRequestFilter> onSelected;

  const _CountCards({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final count = ref.watch(lockPendingCountProvider).valueOrNull;

    final cards = [
      (LockRequestFilter.awaitingMine, l10n.lockFilterAwaitingMine, count?.awaitingMyVote),
      (LockRequestFilter.pending, l10n.lockFilterPending, count?.pending),
      (LockRequestFilter.resolved, l10n.lockFilterResolved, count?.resolved),
    ];

    // Căn trái + giới hạn bề ngang: Column cha dùng stretch nên phải bọc Align thì maxWidth mới có hiệu lực
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _CountCard(
                label: cards[i].$2,
                value: cards[i].$3,
                selected: selected == cards[i].$1,
                onTap: () => onSelected(cards[i].$1),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final int? value;
  final bool selected;
  final VoidCallback onTap;

  const _CountCard({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final value = this.value;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? cs.primary.withValues(alpha: 0.06) : cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? cs.primary : theme.dividerColor, width: selected ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          // Chiều cao theo nội dung (line-height thật của font), không cố định → không tràn
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  value == null
                      ? Container(
                          width: 24,
                          height: 16,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      : Text(
                          '$value',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                ],
              ),
            ),
        ),
      ),
    );
  }
}

/// Điện thoại: thẻ đếm thành một hàng chip cuộn ngang, số nằm trong chip.
class _FilterChips extends ConsumerWidget {
  final LockRequestFilter selected;
  final ValueChanged<LockRequestFilter> onSelected;

  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final count = ref.watch(lockPendingCountProvider).valueOrNull;
    String label(String text, int? n) => n == null ? text : '$text $n';

    final chips = [
      (LockRequestFilter.awaitingMine, label(l10n.lockFilterAwaitingMine, count?.awaitingMyVote)),
      (LockRequestFilter.pending, label(l10n.lockFilterPending, count?.pending)),
      (LockRequestFilter.resolved, label(l10n.lockFilterResolved, count?.resolved)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            ChoiceChip(
              label: Text(chips[i].$2),
              selected: selected == chips[i].$1,
              showCheckmark: false,
              onSelected: (_) => onSelected(chips[i].$1),
            ),
          ],
        ],
      ),
    );
  }
}
