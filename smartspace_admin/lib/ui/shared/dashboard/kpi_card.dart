import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

/// Định dạng số theo locale (1,248 / 1.248).
String formatCount(BuildContext context, num value) =>
    NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(value);

/// % thay đổi so với kỳ trước. Null khi kỳ trước = 0 (không so sánh được).
double? percentChange(num current, num previous) {
  if (previous == 0) return null;
  return (current - previous) / previous * 100;
}

/// Ý nghĩa của chiều tăng/giảm — quyết định màu semantic của dòng so sánh.
enum ChangeTone {
  /// Tăng là tốt (vd: người dùng mới, số báo cáo đã xử lý).
  higherIsBetter,

  /// Giảm là tốt (vd: thời gian xử lý trung bình).
  lowerIsBetter,

  /// Tăng/giảm không mang nghĩa tốt/xấu → màu trung tính.
  neutral,
}

/// Dòng chú thích "+12% so với 30 ngày trước" cho [KpiCard].
class KpiFootnote {
  final String text;
  final IconData? icon;
  final Color? color;

  const KpiFootnote(this.text, {this.icon, this.color});

  /// So sánh 30 ngày gần nhất với 30 ngày trước. Null khi chưa có dữ liệu kỳ này.
  static KpiFootnote? change(
    BuildContext context, {
    required num? current,
    required num? previous,
    ChangeTone tone = ChangeTone.neutral,
  }) {
    if (current == null) return null;
    final l10n = AppLocalizations.of(context)!;
    final change = previous == null ? null : percentChange(current, previous);
    if (change == null) return KpiFootnote(l10n.noPreviousPeriodData);

    final rounded = change.round();
    final sign = rounded > 0 ? '+' : (rounded < 0 ? '−' : '');
    final icon = rounded > 0
        ? Icons.trending_up
        : (rounded < 0 ? Icons.trending_down : Icons.trending_flat);

    Color? color;
    if (rounded != 0 && tone != ChangeTone.neutral) {
      final isGood = (rounded > 0) == (tone == ChangeTone.higherIsBetter);
      color = isGood
          ? AppSemanticColors.of(context).success
          : Theme.of(context).colorScheme.error;
    }

    return KpiFootnote(
      l10n.changeVsPrevious30Days('$sign${rounded.abs()}%'),
      icon: icon,
      color: color,
    );
  }
}

/// KPI card: label + icon, giá trị lớn, dòng chú thích tuỳ chọn.
class KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final KpiFootnote? footnote;
  final bool compact;

  const KpiCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.footnote,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final footnoteColor = footnote?.color ?? mutedColor;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (compact
                              ? theme.textTheme.bodySmall
                              : theme.textTheme.bodyMedium)
                          ?.copyWith(color: mutedColor),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.all(compact ? 6 : 8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: compact ? 16 : 20, color: iconColor),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            value,
            style:
                (compact
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.headlineMedium)
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (footnote!.icon != null) ...[
                  Icon(footnote!.icon, size: 14, color: footnoteColor),
                  const SizedBox(width: 2),
                ],
                Expanded(
                  child: Text(
                    footnote!.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: footnoteColor,
                    ),
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

/// Lưới KPI: rộng >= 900 → 1 hàng 4 cột, còn lại 2 cột. Các thẻ cùng hàng cao bằng nhau.
class KpiGrid extends StatelessWidget {
  final List<Widget> cards;
  final bool compact;

  const KpiGrid({super.key, required this.cards, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        final gap = compact ? 8.0 : 16.0;
        final rows = <Widget>[];
        for (var i = 0; i < cards.length; i += columns) {
          final end = (i + columns).clamp(0, cards.length);
          final rowCards = cards.sublist(i, end);
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) SizedBox(width: gap),
                    // Ô trống giữ độ rộng cột khi hàng cuối thiếu thẻ
                    Expanded(
                      child: j < rowCards.length
                          ? rowCards[j]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}

/// Banner lỗi gọn trong một dòng (dùng cho khối thống kê).
class InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const InlineErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
          TextButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }
}
