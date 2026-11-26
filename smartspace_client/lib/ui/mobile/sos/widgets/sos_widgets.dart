import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/emergency/widgets/emergency_contact_widgets.dart';

/// Giờ:phút:giây theo ngôn ngữ đang dùng.
String formatSosTime(BuildContext context, DateTime? time) {
  if (time == null) return '—';
  return DateFormat.Hms(Localizations.localeOf(context).toLanguageTag()).format(time.toLocal());
}

/// Bốn số khẩn cấp quốc gia, mỗi nút gọi thẳng.
class SosEmergencyNumbers extends StatelessWidget {
  const SosEmergencyNumbers({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final numbers = [
      ('113', l10n.sosCallPolice),
      ('115', l10n.sosCallAmbulance),
      ('114', l10n.sosCallFire),
      ('112', l10n.sosCallRescue),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: numbers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 52,
      ),
      itemBuilder: (context, index) {
        final (number, label) = numbers[index];
        return OutlinedButton.icon(
          onPressed: () => callEmergencyPhone(context, number),
          icon: const Icon(Icons.call_outlined, size: 20),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }
}

/// Khối trạng thái lớn ở đầu màn hình SOS: nền đỏ khi còn mở, nền trung tính khi đã kết thúc.
class SosStatusPanel extends StatelessWidget {
  final bool open;
  final String title;
  final List<Widget> details;

  const SosStatusPanel({super.key, required this.open, required this.title, this.details = const []});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = open ? scheme.errorContainer : scheme.surfaceContainerLow;
    final foreground = open ? scheme.onErrorContainer : scheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: open ? Border.all(color: scheme.error.withValues(alpha: 0.4)) : null,
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: open ? scheme.error : scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                open ? Icons.sos : Icons.check_circle_outline,
                color: open ? scheme.onError : foreground,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(color: foreground, fontWeight: FontWeight.w700),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...details,
            ],
          ],
        ),
      ),
    );
  }
}

/// Dòng phụ trong khối trạng thái, cùng màu chữ với khối.
class SosStatusLine extends StatelessWidget {
  final String text;
  final IconData? icon;

  const SosStatusLine(this.text, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = DefaultTextStyle.of(context).style.color;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: color))),
        ],
      ),
    );
  }
}
