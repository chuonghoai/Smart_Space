import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/delegation/models/delegation_model.dart';
import 'package:smartspace_staff/features/delegation/providers/delegation_providers.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/ui/mobile/delegation/widgets/delegation_common.dart';

/// Bottom sheet nhờ đồng nghiệp làm giùm: chọn người → xem tiền → gửi.
/// Trả về true khi gửi thành công.
class DelegationRequestSheet extends ConsumerStatefulWidget {
  final String reportId;
  final DelegationReportStateModel state;

  const DelegationRequestSheet({super.key, required this.reportId, required this.state});

  static Future<bool?> show(BuildContext context, {required String reportId, required DelegationReportStateModel state}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => DelegationRequestSheet(reportId: reportId, state: state),
    );
  }

  @override
  ConsumerState<DelegationRequestSheet> createState() => _DelegationRequestSheetState();
}

class _DelegationRequestSheetState extends ConsumerState<DelegationRequestSheet> {
  final _noteCtrl = TextEditingController();
  ColleagueModel? _selected;
  bool _sending = false;

  bool get _insufficient => widget.state.balance < widget.state.bonusAmount;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final helper = _selected;
    if (helper == null || _sending || _insufficient) return;
    setState(() => _sending = true);

    final error = await ref.read(delegationActionsProvider).request(
          reportId: widget.reportId,
          helperId: helper.id,
          note: _noteCtrl.text,
        );
    if (!mounted) return;
    setState(() => _sending = false);

    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colleagues = ref.watch(colleagueSearchProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                l10n.delegationSheetTitle,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (value) => ref.read(colleagueSearchProvider.notifier).search(value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.delegationSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _ColleagueList(
              state: colleagues,
              selectedId: _selected?.id,
              onSelected: (colleague) => setState(() => _selected = colleague),
              onLoadMore: () => ref.read(colleagueSearchProvider.notifier).loadMore(),
              onRetry: () => ref.read(colleagueSearchProvider.notifier).loadFirst(),
            )),
            Divider(height: 1, color: cs.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MoneySummary(state: widget.state, insufficient: _insufficient),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteCtrl,
                    maxLength: 500,
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      labelText: l10n.delegationNoteLabel,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Text(
                    l10n.delegationHoldHint,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _selected == null || _sending || _insufficient ? null : _send,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    icon: _sending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_selected == null ? l10n.delegationChooseColleague : l10n.delegationSendAction),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Đồng nghiệp nhận bao nhiêu, ví mình bị trừ bao nhiêu, số dư hiện tại.
class _MoneySummary extends StatelessWidget {
  final DelegationReportStateModel state;
  final bool insufficient;

  const _MoneySummary({required this.state, required this.insufficient});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget row(String label, String value, {Color? valueColor}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: valueColor ?? cs.onSurface),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(
            l10n.delegationHelperReceives,
            l10n.delegationHelperReceivesValue(
              formatDelegationMoney(state.commissionAmount),
              formatDelegationMoney(state.bonusAmount),
            ),
          ),
          row(l10n.delegationYouPay, '-${formatDelegationMoney(state.bonusAmount)}đ', valueColor: cs.error),
          row(l10n.delegationCurrentBalance, '${formatDelegationMoney(state.balance)}đ'),
          const SizedBox(height: 4),
          Text(
            l10n.delegationBonusRate(formatDelegationRate(state.ratePercent)),
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (insufficient) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: cs.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.delegationInsufficientBalance,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.error, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ColleagueList extends StatelessWidget {
  final PagedState<ColleagueModel> state;
  final String? selectedId;
  final ValueChanged<ColleagueModel> onSelected;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  const _ColleagueList({
    required this.state,
    required this.selectedId,
    required this.onSelected,
    required this.onLoadMore,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Text(l10n.delegationNoColleagues, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 200) onLoadMore();
        return false;
      },
      child: ListView.builder(
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }
          final colleague = state.items[index];
          final selected = colleague.id == selectedId;
          return ListTile(
            onTap: () => onSelected(colleague),
            selected: selected,
            selectedTileColor: cs.primaryContainer.withValues(alpha: 0.35),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              foregroundImage: colleague.avatarUrl != null ? NetworkImage(colleague.avatarUrl!) : null,
              child: Icon(Icons.person, color: cs.onPrimaryContainer),
            ),
            title: Text(colleague.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: colleague.positionName != null
                ? Text(colleague.positionName!, maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
            trailing: Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? cs.primary : cs.outline,
            ),
          );
        },
      ),
    );
  }
}
