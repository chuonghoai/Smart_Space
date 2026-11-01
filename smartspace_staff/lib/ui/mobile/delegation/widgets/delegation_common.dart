import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/core/widgets/confirm_dialog.dart';
import 'package:smartspace_staff/features/delegation/models/delegation_model.dart';
import 'package:smartspace_staff/features/delegation/providers/delegation_providers.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

final NumberFormat _money = NumberFormat('#,###', 'vi_VN');

/// Số tiền không kèm đơn vị (đơn vị "đ" nằm trong chuỗi L10n).
String formatDelegationMoney(double amount) => _money.format(amount);

String formatDelegationTime(DateTime time) => DateFormat('HH:mm dd/MM').format(time.toLocal());

/// Phần trăm gọn: 50 → "50", 12.5 → "12.5".
String formatDelegationRate(double rate) => rate == rate.roundToDouble() ? rate.round().toString() : rate.toString();

extension DelegationStatusUi on DelegationStatus {
  String label(AppLocalizations l10n) => switch (this) {
        DelegationStatus.pending => l10n.delegationStatusPending,
        DelegationStatus.accepted => l10n.delegationStatusAccepted,
        DelegationStatus.declined => l10n.delegationStatusDeclined,
        DelegationStatus.cancelled => l10n.delegationStatusCancelled,
        DelegationStatus.expired => l10n.delegationStatusExpired,
        DelegationStatus.completed => l10n.delegationStatusCompleted,
        DelegationStatus.revoked || DelegationStatus.unknown => l10n.delegationStatusRevoked,
      };

  /// Đang chờ → warning, đang làm → info, hoàn tất → success, kết thúc không thành → trung tính.
  Color color(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return switch (this) {
      DelegationStatus.pending => semantic.warning,
      DelegationStatus.accepted => semantic.info,
      DelegationStatus.completed => semantic.success,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }
}

/// Chip trạng thái: luôn có chữ, màu chỉ để nhấn mạnh.
class DelegationStatusChip extends StatelessWidget {
  final DelegationStatus status;

  const DelegationStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = status.color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label(l10n),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Nhận / từ chối / huỷ có hỏi xác nhận, báo kết quả bằng SnackBar. Trả về true khi thành công.
class DelegationActionHandler {
  final BuildContext context;
  final WidgetRef ref;

  const DelegationActionHandler(this.context, this.ref);

  Future<bool> accept(DelegationModel delegation) {
    final l10n = AppLocalizations.of(context)!;
    return _confirmAndRun(
      title: l10n.delegationAcceptConfirmTitle,
      message: l10n.delegationAcceptConfirmMessage,
      okLabel: l10n.delegationAcceptAction,
      successMessage: l10n.delegationAcceptedSuccess,
      action: () => ref.read(delegationActionsProvider).accept(delegation),
    );
  }

  Future<bool> decline(DelegationModel delegation) {
    final l10n = AppLocalizations.of(context)!;
    return _confirmAndRun(
      title: l10n.delegationDeclineConfirmTitle,
      message: l10n.delegationDeclineConfirmMessage(delegation.requester.fullName),
      okLabel: l10n.delegationDeclineAction,
      successMessage: l10n.delegationDeclinedSuccess,
      action: () => ref.read(delegationActionsProvider).decline(delegation),
    );
  }

  Future<bool> cancel(DelegationModel delegation) {
    final l10n = AppLocalizations.of(context)!;
    return _confirmAndRun(
      title: l10n.delegationCancelConfirmTitle,
      message: l10n.delegationCancelConfirmMessage,
      okLabel: l10n.delegationCancelAction,
      successMessage: l10n.delegationCancelledSuccess,
      action: () => ref.read(delegationActionsProvider).cancel(delegation),
    );
  }

  Future<bool> _confirmAndRun({
    required String title,
    required String message,
    required String okLabel,
    required String successMessage,
    required Future<String?> Function() action,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: title,
      message: message,
      okLabel: okLabel,
      cancelLabel: l10n.cancel,
    );
    if (confirmed != true || !context.mounted) return false;

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final error = await action();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(error ?? successMessage),
        backgroundColor: error != null ? errorColor : null,
      ));
    return error == null;
  }
}
