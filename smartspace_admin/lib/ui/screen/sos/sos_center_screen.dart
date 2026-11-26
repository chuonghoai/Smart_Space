import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:smartspace_admin/features/sos/application/sos_admin_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/sos/sos_widgets.dart';

/// Danh sách tín hiệu SOS: tab đang mở (mới nhất trước) và tab đã kết thúc.
class SosCenterScreen extends ConsumerWidget {
  const SosCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final openCount = ref.watch(sosOpenCountProvider).valueOrNull ?? 0;

    return AppLayout(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Material(
              color: theme.colorScheme.surface,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: theme.dividerColor,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.sosTabOpen),
                        if (openCount > 0) ...[
                          const SizedBox(width: 8),
                          Badge(
                            label: Text('$openCount'),
                            backgroundColor: theme.colorScheme.error,
                            textColor: theme.colorScheme.onError,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(text: l10n.sosTabResolved),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _SosList(filter: SosFilter.open),
                  _SosList(filter: SosFilter.resolved),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosList extends ConsumerWidget {
  final SosFilter filter;

  const _SosList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(sosListProvider(filter));
    final notifier = ref.read(sosListProvider(filter).notifier);

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.sosLoadFailed, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            TextButton(onPressed: notifier.refresh, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: state.items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  child: Text(
                    filter == SosFilter.open ? l10n.sosEmptyOpen : l10n.sosEmptyResolved,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: OutlinedButton(
                            onPressed: state.isLoadingMore ? null : notifier.loadMore,
                            child: state.isLoadingMore
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(l10n.loadMore),
                          ),
                        ),
                      );
                    }
                    return _SosRow(sos: state.items[index]);
                  },
                ),
              ),
            ),
    );
  }
}

class _SosRow extends StatelessWidget {
  final SosAlertModel sos;

  const _SosRow({required this.sos});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final urgent = sos.status == ESosStatus.active;
    final lost = sosSignalLost(sos);

    return Material(
      color: urgent ? scheme.errorContainer : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: urgent ? BorderSide(color: scheme.error.withValues(alpha: 0.4)) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RouterPath.sosDetailWithId(sos.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              SosIconBadge(open: sos.isOpen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sos.user.fullName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: urgent ? scheme.onErrorContainer : scheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lost
                          ? l10n.sosSignalLost(formatSosDateTime(context, sos.lastLocationAt))
                          : l10n.sosSentAt(formatSosDateTime(context, sos.createdAt)),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: urgent ? scheme.onErrorContainer : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(child: SosStatusLabel(sos: sos, onUrgentSurface: urgent)),
              Icon(Icons.chevron_right, color: urgent ? scheme.onErrorContainer : scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
