import 'package:flutter/material.dart';
import 'package:mobile_shared/features/map/widgets/map_filter_chip_bar.dart';
import 'package:smartspace_client/features/reports/models/map_report_filter.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

/// Hàng chip lọc report trên bản đồ Client (chọn một).
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
    return MapFilterChipBar<MapReportFilter>(
      options: [
        for (final filter in MapReportFilter.values)
          MapFilterChipOption(value: filter, label: labelOf(filter, l10n)),
      ],
      selected: selected,
      onSelected: onSelected,
    );
  }
}
