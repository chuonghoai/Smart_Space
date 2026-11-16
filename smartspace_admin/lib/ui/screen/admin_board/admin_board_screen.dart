import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/account_lock/application/account_lock_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/mobile/admin_board/mobile_admin_board_view.dart';
import 'package:smartspace_admin/ui/screen/admin_board/lock_requests/lock_requests_tab.dart';
import 'package:smartspace_admin/ui/screen/admin_board/web_admin_board_view.dart';

/// Hội đồng quản trị: tab "Quản trị viên" và tab "Đề xuất khoá" (biểu quyết khóa tài khoản).
class AdminBoardScreen extends StatelessWidget {
  /// 'lock-requests' → mở sẵn tab đề xuất khoá.
  final String? initialTab;

  /// Đề xuất cần mở sẵn (vd: từ thông báo).
  final String? initialRequestId;

  const AdminBoardScreen({super.key, this.initialTab, this.initialRequestId});

  static const String lockRequestsTab = 'lock-requests';

  @override
  Widget build(BuildContext context) {
    final openLockTab = initialTab == lockRequestsTab ||
        (initialRequestId != null && initialRequestId!.isNotEmpty);

    return AppLayout(
      child: DefaultTabController(
        length: 2,
        initialIndex: openLockTab ? 1 : 0,
        child: Column(
          children: [
            const _AdminBoardTabBar(),
            Expanded(
              child: TabBarView(
                children: [
                  kIsWeb ? const WebAdminBoardView() : const MobileAdminBoardView(),
                  LockRequestsTab(initialRequestId: initialRequestId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminBoardTabBar extends ConsumerWidget {
  const _AdminBoardTabBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final awaiting = ref.watch(lockPendingCountProvider).valueOrNull?.awaitingMyVote ?? 0;

    return Material(
      color: cs.surface,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: theme.dividerColor,
        tabs: [
          Tab(text: l10n.admins),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.lockRequestsTab),
                if (awaiting > 0) ...[
                  const SizedBox(width: 8),
                  Semantics(
                    label: l10n.lockAwaitingYourVote,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        awaiting > 99 ? '99+' : '$awaiting',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onError,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
