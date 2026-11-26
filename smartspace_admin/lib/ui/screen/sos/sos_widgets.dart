import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Quá lâu không có vị trí mới (client gửi mỗi 15 giây) thì coi như mất tín hiệu.
const Duration kSosSignalLostAfter = Duration(minutes: 2);

bool sosSignalLost(SosAlertModel sos) {
  final last = sos.lastLocationAt;
  return sos.isOpen && last != null && DateTime.now().difference(last.toLocal()) > kSosSignalLostAfter;
}

String formatSosDateTime(BuildContext context, DateTime? time) {
  if (time == null) return '—';
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('HH:mm:ss · dd/MM', locale).format(time.toLocal());
}

Future<void> callSosPhone(BuildContext context, String? phone) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  if (phone == null || phone.trim().isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.noPhoneNumber)));
    return;
  }
  try {
    await launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s+'), '')));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.cannotMakePhoneCall)));
  }
}

/// Badge tròn biểu tượng SOS đảm bảo tương phản tốt ở cả Light và Dark Mode.
class SosIconBadge extends StatelessWidget {
  final bool open;
  final double size;

  const SosIconBadge({super.key, required this.open, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: open ? scheme.error : scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.sos,
        color: open ? scheme.onError : scheme.onSurfaceVariant,
        size: size * 0.58,
      ),
    );
  }
}

/// Nhãn trạng thái: chấm màu ngữ nghĩa + chữ rõ nét ở cả Light và Dark Mode.
class SosStatusLabel extends StatelessWidget {
  final SosAlertModel sos;
  final bool onUrgentSurface;

  const SosStatusLabel({super.key, required this.sos, this.onUrgentSurface = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);

    final (Color dot, String label) = switch (sos.status) {
      ESosStatus.active => (
          onUrgentSurface ? theme.colorScheme.onErrorContainer : theme.colorScheme.error,
          l10n.sosStatusActive,
        ),
      ESosStatus.acknowledged => (semantic.warning, l10n.sosStatusAcknowledged),
      ESosStatus.resolved => switch (sos.resolution) {
          ESosResolution.safeByUser => (semantic.success, l10n.sosResolutionSafe),
          ESosResolution.falseAlarm => (theme.colorScheme.outline, l10n.sosResolutionFalseAlarm),
          _ => (semantic.success, l10n.sosResolutionHandled),
        },
    };

    final textColor = onUrgentSurface ? theme.colorScheme.onErrorContainer : theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
