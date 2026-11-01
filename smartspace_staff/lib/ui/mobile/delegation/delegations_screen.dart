import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_staff/features/delegation/models/delegation_model.dart';
import 'package:smartspace_staff/features/delegation/providers/delegation_providers.dart';
import 'package:smartspace_staff/features/reports/utils/report_severity_ext.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/routes/router_path.dart';
import 'package:smartspace_staff/ui/mobile/delegation/widgets/delegation_common.dart';

/// Việc nhờ làm giùm: tab "Được nhờ" (mình là người được nhờ) và "Đã nhờ" (mình đi nhờ).
class DelegationsScreen extends StatelessWidget {
  final DelegationBox initialBox;

  const DelegationsScreen({super.key, this.initialBox = DelegationBox.received});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: DelegationBox.values.length,
      initialIndex: DelegationBox.values.indexOf(initialBox),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.delegationScreenTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.delegationTabReceived),
              Tab(text: l10n.delegationTabSent),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DelegationList(box: DelegationBox.received),
            _DelegationList(box: DelegationBox.sent),
          ],
        ),
      ),
    );
  }
}

class _DelegationList extends ConsumerWidget {
  final DelegationBox box;

  const _DelegationList({required this.box});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(delegationListProvider(box));
    final notifier = ref.read(delegationListProvider(box).notifier);

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty) {
      final failed = state.error != null;
      // Vẫn kéo-để-làm-mới được khi trống
      return RefreshIndicator(
        onRefresh: notifier.loadFirst,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
            Icon(
              failed ? Icons.cloud_off_outlined : Icons.handshake_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              failed
                  ? l10n.delegationLoadFailed
                  : (box == DelegationBox.received ? l10n.delegationEmptyReceived : l10n.delegationEmptySent),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (failed)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton(onPressed: notifier.loadFirst, child: Text(l10n.retry)),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.loadFirst,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 300) notifier.loadMore();
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Center(
                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return _DelegationCard(delegation: state.items[index], box: box);
          },
        ),
      ),
    );
  }
}

class _DelegationCard extends ConsumerWidget {
  final DelegationModel delegation;
  final DelegationBox box;

  const _DelegationCard({required this.delegation, required this.box});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final received = box == DelegationBox.received;
    final pending = delegation.status == DelegationStatus.pending;
    final actions = DelegationActionHandler(context, ref);
    final severityColor = delegation.severity.getColor(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RouterPath.reportDetail.replaceAll(':id', delegation.reportId)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      delegation.reportTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DelegationStatusChip(status: delegation.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                received
                    ? l10n.delegationFrom(delegation.requester.fullName)
                    : l10n.delegationTo(delegation.helper.fullName),
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      delegation.severity.getLocalizedText(l10n),
                      style: theme.textTheme.labelSmall?.copyWith(color: severityColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    l10n.delegationBonusLabel(formatDelegationMoney(delegation.bonusAmount)),
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (pending && delegation.expiresAt != null)
                    Text(
                      l10n.delegationExpiresAt(formatDelegationTime(delegation.expiresAt!)),
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
              if (pending) ...[
                const SizedBox(height: 12),
                if (received)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => actions.decline(delegation),
                          child: Text(l10n.delegationDeclineAction),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => actions.accept(delegation),
                          child: Text(l10n.delegationAcceptAction),
                        ),
                      ),
                    ],
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => actions.cancel(delegation),
                      style: TextButton.styleFrom(foregroundColor: cs.error),
                      child: Text(l10n.delegationCancelAction),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
