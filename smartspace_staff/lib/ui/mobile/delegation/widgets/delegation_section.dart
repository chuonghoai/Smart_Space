import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/delegation/models/delegation_model.dart';
import 'package:smartspace_staff/features/delegation/providers/delegation_providers.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/ui/mobile/delegation/delegation_request_sheet.dart';
import 'package:smartspace_staff/ui/mobile/delegation/widgets/delegation_common.dart';

/// Khu vực "nhờ làm giùm" trên màn chi tiết report:
/// - có yêu cầu đang hoạt động → banner theo vai trò (người nhờ / người được nhờ) kèm thao tác;
/// - nhờ được (hoặc chỉ vướng số dư) → nút "Nhờ làm giùm";
/// - còn lại (không phải task của mình, đang xử lý lại...) → không hiện gì.
class DelegationSection extends ConsumerWidget {
  final String reportId;

  const DelegationSection({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(delegationReportStateProvider(reportId)).valueOrNull;
    final staffId = ref.watch(currentStaffIdProvider).valueOrNull;
    if (state == null) return const SizedBox.shrink();

    final active = state.activeDelegation;
    if (active != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _ActiveDelegationBanner(delegation: active, staffId: staffId),
      );
    }
    if (state.canRequest || state.isInsufficientBalance) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _RequestButton(reportId: reportId, state: state),
      );
    }
    return const SizedBox.shrink();
  }
}

class _RequestButton extends StatelessWidget {
  final String reportId;
  final DelegationReportStateModel state;

  const _RequestButton({required this.reportId, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: state.canRequest
              ? () async {
                  final sent = await DelegationRequestSheet.show(context, reportId: reportId, state: state);
                  if (sent == true && context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(l10n.delegationSentSuccess)));
                  }
                }
              : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.handshake_outlined, size: 20),
          label: Text(l10n.delegationRequestAction),
        ),
        if (state.isInsufficientBalance) ...[
          const SizedBox(height: 6),
          Text(
            l10n.delegationInsufficientBalance,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
          ),
        ],
      ],
    );
  }
}

class _ActiveDelegationBanner extends ConsumerWidget {
  final DelegationModel delegation;
  final String? staffId;

  const _ActiveDelegationBanner({required this.delegation, required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = delegation.status.color(context);
    final isHelper = delegation.isHelper(staffId);
    final pending = delegation.status == DelegationStatus.pending;
    final actions = DelegationActionHandler(context, ref);

    final headline = switch ((isHelper, pending)) {
      (true, true) => l10n.delegationPendingHelperBanner(delegation.requester.fullName),
      (true, false) => l10n.delegationAcceptedHelperBanner(delegation.requester.fullName),
      (false, true) => l10n.delegationPendingRequesterBanner(delegation.helper.fullName),
      (false, false) => l10n.delegationAcceptedRequesterBanner(delegation.helper.fullName),
    };
    final money = isHelper
        ? l10n.delegationHelperEarns(
            formatDelegationMoney(delegation.commissionAmount),
            formatDelegationMoney(delegation.bonusAmount),
          )
        : l10n.delegationBonusHeld(formatDelegationMoney(delegation.bonusAmount));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.handshake_outlined, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(money, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    if (pending && delegation.expiresAt != null)
                      Text(
                        l10n.delegationExpiresAt(formatDelegationTime(delegation.expiresAt!)),
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    if (delegation.note != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '“${delegation.note!}”',
                        style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              DelegationStatusChip(status: delegation.status),
            ],
          ),
          if (pending) ...[
            const SizedBox(height: 10),
            if (isHelper)
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
            else if (delegation.isRequester(staffId))
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
    );
  }
}
