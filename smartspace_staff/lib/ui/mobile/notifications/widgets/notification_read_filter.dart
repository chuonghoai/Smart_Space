import 'package:flutter/material.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

/// Thanh chọn Tất cả / Chưa đọc của màn Thông báo.
///
/// Một rãnh nền (surface, viền outlineVariant) chia đều 2 nửa, nhãn căn giữa; nửa đang chọn là khối
/// primary/onPrimary — cặp màu của nút Primary. Không dùng primaryContainer cho khối chọn vì ở Light
/// nó trùng tông với nền xám (đo được tỉ lệ 1.00:1), khối chọn không nhìn ra. Full-width trên điện
/// thoại, tối đa [_maxWidth] và căn giữa trên màn rộng. Cao 48dp (vùng chạm tối thiểu).
class NotificationReadFilter extends StatelessWidget {
  final bool unreadOnly;

  /// Số thông báo chưa đọc (số trên badge); 0 thì không hiện số.
  final int unreadCount;
  final ValueChanged<bool> onChanged;

  const NotificationReadFilter({
    super.key,
    required this.unreadOnly,
    required this.unreadCount,
    required this.onChanged,
  });

  static const double _maxWidth = 480;
  static const double _height = 48;
  static const double _inset = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150);
    final countText = unreadCount > 99 ? '99+' : '$unreadCount';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Container(
          height: _height,
          padding: const EdgeInsets.all(_inset),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _Segment(
                  label: l10n.filterAll,
                  semanticsLabel: l10n.filterAll,
                  selected: !unreadOnly,
                  duration: duration,
                  onTap: () => onChanged(false),
                ),
              ),
              const SizedBox(width: _inset),
              Expanded(
                child: _Segment(
                  label: l10n.notificationFilterUnread,
                  semanticsLabel: unreadCount > 0
                      ? l10n.notificationFilterUnreadCount(countText)
                      : l10n.notificationFilterUnread,
                  badge: unreadCount > 0 ? countText : null,
                  selected: unreadOnly,
                  duration: duration,
                  onTap: () => onChanged(true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final String semanticsLabel;
  final String? badge;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.duration,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = BorderRadius.circular(8);

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: selected ? null : onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: selected ? null : onTap,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOut,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0),
              borderRadius: radius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  _CountBadge(text: badge!, onPrimarySurface: selected),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Số chưa đọc: pill primary/onPrimary — cùng cặp màu với chấm "chưa đọc" trên từng dòng thông báo.
/// Nằm trên khối đang chọn (nền primary) thì đảo màu để không chìm.
class _CountBadge extends StatelessWidget {
  final String text;
  final bool onPrimarySurface;

  const _CountBadge({required this.text, required this.onPrimarySurface});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: onPrimarySurface ? colorScheme.onPrimary : colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: onPrimarySurface ? colorScheme.primary : colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

