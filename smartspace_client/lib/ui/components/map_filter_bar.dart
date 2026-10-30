import 'package:flutter/material.dart';
import 'package:smartspace_client/features/reports/models/map_report_filter.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

/// Hàng chip lọc report trên bản đồ (chọn một), cuộn ngang khi không đủ chỗ.
/// Chip có nền đặc theo theme → chữ không đặt trực tiếp lên bản đồ.
class MapFilterBar extends StatelessWidget {
  final MapReportFilter selected;
  final ValueChanged<MapReportFilter> onSelected;

  const MapFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static String labelOf(MapReportFilter filter, AppLocalizations l10n) => switch (filter) {
        MapReportFilter.all => l10n.mapFilterAll,
        MapReportFilter.mine => l10n.myReports,
        MapReportFilter.pending => l10n.reportStatusPending,
        MapReportFilter.processing => l10n.reportStatusProcessing,
        MapReportFilter.processed => l10n.reportStatusProcessed,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: MapReportFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = MapReportFilter.values[index];
          final isSelected = filter == selected;
          return Center(
            child: ChoiceChip(
              label: Text(labelOf(filter, l10n)),
              selected: isSelected,
              onSelected: (_) => onSelected(filter),
              showCheckmark: false,
              elevation: 3,
              pressElevation: 1,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
              backgroundColor: colorScheme.surface,
              selectedColor: colorScheme.primaryContainer,
              side: BorderSide(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }
}
