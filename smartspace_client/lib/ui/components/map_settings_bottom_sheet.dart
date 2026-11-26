import 'package:flutter/material.dart';
import 'package:smartspace_client/features/reports/models/map_report_filter.dart';
import 'package:smartspace_client/features/reports/models/report_timeframe.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

class MapSettingsBottomSheet extends StatefulWidget {
  final bool isDensityEnabled;
  final ValueChanged<bool> onDensityToggle;
  final MapReportFilter currentFilter;
  final ValueChanged<MapReportFilter> onFilterSelected;
  final ReportTimeframe currentTimeframe;
  final ValueChanged<ReportTimeframe> onTimeframeSelected;

  const MapSettingsBottomSheet({
    super.key,
    required this.isDensityEnabled,
    required this.onDensityToggle,
    required this.currentFilter,
    required this.onFilterSelected,
    required this.currentTimeframe,
    required this.onTimeframeSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isDensityEnabled,
    required ValueChanged<bool> onDensityToggle,
    required MapReportFilter currentFilter,
    required ValueChanged<MapReportFilter> onFilterSelected,
    required ReportTimeframe currentTimeframe,
    required ValueChanged<ReportTimeframe> onTimeframeSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => MapSettingsBottomSheet(
        isDensityEnabled: isDensityEnabled,
        onDensityToggle: onDensityToggle,
        currentFilter: currentFilter,
        onFilterSelected: onFilterSelected,
        currentTimeframe: currentTimeframe,
        onTimeframeSelected: onTimeframeSelected,
      ),
    );
  }

  @override
  State<MapSettingsBottomSheet> createState() => _MapSettingsBottomSheetState();
}

class _MapSettingsBottomSheetState extends State<MapSettingsBottomSheet> {
  late bool _isDensityEnabled;
  late MapReportFilter _currentFilter;
  late ReportTimeframe _currentTimeframe;

  @override
  void initState() {
    super.initState();
    _isDensityEnabled = widget.isDensityEnabled;
    _currentFilter = widget.currentFilter;
    _currentTimeframe = widget.currentTimeframe;
  }

  static String _filterLabel(MapReportFilter filter, AppLocalizations l10n) => switch (filter) {
        MapReportFilter.all => l10n.mapFilterAll,
        MapReportFilter.mine => l10n.myReports,
        MapReportFilter.pending => l10n.reportStatusPending,
        MapReportFilter.processing => l10n.reportStatusProcessing,
        MapReportFilter.processed => l10n.reportStatusProcessed,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      elevation: 10,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: colorScheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      l10n.mapSettings,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Section 1: Density Map Layer Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.layers_rounded, color: colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.mapDensityToggle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.mapDensityDescription,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // High-contrast custom Switch
                      Switch(
                        value: _isDensityEnabled,
                        onChanged: (val) {
                          setState(() => _isDensityEnabled = val);
                          widget.onDensityToggle(val);
                        },
                        activeThumbColor: colorScheme.onPrimary,
                        activeTrackColor: colorScheme.primary,
                        inactiveThumbColor: isDark ? Colors.white : colorScheme.onSurface,
                        inactiveTrackColor: isDark
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.surfaceContainerHigh,
                        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.transparent;
                          }
                          return colorScheme.outline;
                        }),
                        thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Icon(Icons.check, size: 14, color: colorScheme.primary);
                          }
                          return Icon(
                            Icons.close,
                            size: 14,
                            color: isDark ? Colors.black87 : colorScheme.surface,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: Report Status Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.filter_list_rounded, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.filterReports,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MapReportFilter.values.map((filter) {
                    final isSelected = filter == _currentFilter;
                    final label = _filterLabel(filter, l10n);

                    return FilterChip(
                      selected: isSelected,
                      label: Text(label),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                      ),
                      selectedColor: colorScheme.primaryContainer,
                      backgroundColor: colorScheme.surfaceContainerLow,
                      checkmarkColor: colorScheme.primary,
                      side: BorderSide(
                        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (_) {
                        setState(() => _currentFilter = filter);
                        widget.onFilterSelected(filter);
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Section 3: Timeframe Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.filterTimeframe,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ReportTimeframe.values.map((timeframe) {
                    final isSelected = timeframe == _currentTimeframe;
                    final label = timeframe.localizedLabel(context);

                    return FilterChip(
                      selected: isSelected,
                      label: Text(label),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                      ),
                      selectedColor: colorScheme.primaryContainer,
                      backgroundColor: colorScheme.surfaceContainerLow,
                      checkmarkColor: colorScheme.primary,
                      side: BorderSide(
                        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (_) {
                        setState(() => _currentTimeframe = timeframe);
                        widget.onTimeframeSelected(timeframe);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
