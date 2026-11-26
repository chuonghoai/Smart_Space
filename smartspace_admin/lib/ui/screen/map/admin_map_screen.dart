import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:mobile_shared/features/map/models/map_focus_target.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';
import 'package:smartspace_admin/features/reports/models/staff_model.dart';
import 'package:smartspace_admin/features/map/models/spatial_analytics_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

import 'admin_map_controller.dart';
// Conditional import: web vs mobile
import 'admin_map_screen_mobile.dart'
    if (dart.library.html) 'admin_map_screen_web.dart'
    as platform_map;
import 'platform_map_controller.dart';
import 'widgets/map_cluster_sheet.dart';
import 'widgets/map_controls.dart';
import 'widgets/map_density_legend.dart';
import 'widgets/map_filter_bottom_sheet.dart';
import 'widgets/map_legend.dart';
import 'widgets/map_report_sheet.dart';
import 'widgets/map_quick_assign_sheet.dart';
import 'widgets/map_settings_bottom_sheet.dart';
import 'widgets/spatial_hotspot_panel.dart';

/// Có [focus] (mở từ chi tiết report) → camera mở tại report đó; khung đầu tiên được tải mới
/// (bỏ qua cache) rồi mở thẻ của report, hoặc báo nó không khớp bộ lọc hiện tại.
class AdminMapScreen extends ConsumerStatefulWidget {
  final MapFocusTarget? focus;

  const AdminMapScreen({super.key, this.focus});

  @override
  ConsumerState<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends ConsumerState<AdminMapScreen> {
  bool _sheetOpen = false;
  bool _didRequestFocus = false;
  bool _showHotspotsPanel = false;
  PlatformMapController? _platformMapController;

  @override
  void initState() {
    super.initState();
    // Luôn tải lại dữ liệu mới nhất mỗi khi mở giao diện bản đồ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handleRefresh();
      }
    });
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(mapStaffListProvider);
    ref.read(adminMapControllerProvider.notifier).refresh();
    ref.invalidate(spatialAnalyticsProvider);
    await _platformMapController?.refreshViewport();
  }

  void _onHotspotSelected(SpatialHotspotItem hotspot) {
    _platformMapController?.flyToCoordinate(
      hotspot.centerLat,
      hotspot.centerLng,
      zoom: 16.5,
    );
  }

  void _toggleHotspots(bool isWide) {
    if (isWide) {
      setState(() => _showHotspotsPanel = !_showHotspotsPanel);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SpatialHotspotPanel(
        isBottomSheet: true,
        onClose: () => Navigator.of(ctx).pop(),
        onHotspotTap: (item) {
          Navigator.of(ctx).pop();
          _onHotspotSelected(item);
        },
      ),
    );
  }

  void _onViewportChanged(MapBounds bounds) {
    final focus = widget.focus;
    final controller = ref.read(adminMapControllerProvider.notifier);
    if (focus == null || _didRequestFocus) {
      controller.onViewportChanged(bounds);
      return;
    }
    _didRequestFocus = true;
    _loadAndShowFocus(controller, bounds, focus);
  }

  Future<void> _loadAndShowFocus(
    AdminMapController controller,
    MapBounds bounds,
    MapFocusTarget focus,
  ) async {
    await controller.loadNow(bounds);
    if (!mounted) return;

    // Lỗi đã có SnackBar riêng; còn đang tải = request khác (người dùng kéo bản đồ) đã thay thế
    final state = ref.read(mapReportsProvider);
    if (state.error != null || state.isLoading) return;

    final report = state.reports.where((r) => r.id == focus.reportId).firstOrNull;
    if (report != null) {
      _onReportTap(report);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.mapFocusedReportHidden)),
      );
  }

  void _onReportTap(MapReportModel report) {
    ref.read(adminMapControllerProvider.notifier).selectReport(report);

    // Close existing sheet before opening new one
    if (_sheetOpen) {
      Navigator.of(context).pop();
      _sheetOpen = false;
    }

    _sheetOpen = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PointerInterceptor(
        child: MapReportSheet(
          report: report,
          onViewDetail: () {
            Navigator.of(context).pop();
            context.push(RouterPath.reportDetailWithId(report.id));
          },
          onAssign: report.status == 'pending'
              ? () {
                  Navigator.of(context).pop(); // close MapReportSheet
                  _sheetOpen = false;
                  _showQuickAssign(report);
                }
              : null,
        ),
      ),
    ).whenComplete(() => _sheetOpen = false);
  }

  void _showQuickAssign(MapReportModel report) {
    if (_sheetOpen) {
      Navigator.of(context).pop();
      _sheetOpen = false;
    }

    _sheetOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PointerInterceptor(
        child: MapQuickAssignSheet(
          report: report,
          onAssigned: () => _handleRefresh(),
        ),
      ),
    ).whenComplete(() => _sheetOpen = false);
  }

  /// Cluster không tách được nữa → danh sách; bấm một dòng → sheet chi tiết (có phân công).
  void _showClusterSheet(List<MapReportModel> reports) {
    if (_sheetOpen) {
      Navigator.of(context).pop();
      _sheetOpen = false;
    }

    _sheetOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PointerInterceptor(
        child: MapClusterSheet(
          reports: reports,
          onReportTap: (report) {
            Navigator.of(sheetContext).pop();
            _sheetOpen = false;
            _onReportTap(report);
          },
        ),
      ),
    ).whenComplete(() => _sheetOpen = false);
  }

  void _showMapSettings() async {
    if (_sheetOpen) {
      Navigator.of(context).pop();
      _sheetOpen = false;
    }

    final densityState = ref.read(adminReportDensityProvider);
    final currentFilter = ref.read(mapFilterProvider);
    final currentTimeframe = ref.read(mapReportsProvider).timeframe;

    _sheetOpen = true;
    await MapSettingsBottomSheet.show(
      context,
      isDensityEnabled: densityState.isEnabled,
      currentStatus: currentFilter.status,
      currentTimeframe: currentTimeframe,
      onDensityToggle: (val) {
        ref.read(adminReportDensityProvider.notifier).toggleEnabled();
      },
      onStatusSelected: (status) {
        ref.read(mapFilterProvider.notifier).state =
            currentFilter.copyWith(status: status, clearStatus: status == null);
      },
      onTimeframeSelected: (tf) {
        ref.read(adminMapControllerProvider.notifier).setTimeframe(tf);
      },
    );
    _sheetOpen = false;
  }

  void _showFilterSheet() async {
    if (_sheetOpen) {
      Navigator.of(context).pop();
      _sheetOpen = false;
    }

    _sheetOpen = true;
    await MapFilterBottomSheet.show(context);
    _sheetOpen = false;
  }

  void _onStaffStationTap(StaffModel staff) {
    if (_sheetOpen) {
      Navigator.of(context).pop();
      _sheetOpen = false;
    }

    _sheetOpen = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        final theme = Theme.of(sheetContext);
        final cs = theme.colorScheme;
        return PointerInterceptor(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppNetworkImage(
                      url: staff.avatarUrl,
                      width: 48,
                      height: 48,
                      isCircle: true,
                      errorWidget: CircleAvatar(
                        radius: 24,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(
                          Icons.person_outline,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (staff.positionName != null &&
                              staff.positionName!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                staff.positionName!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mapStaffStationSheetTitle,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (staff.baseAddress != null &&
                          staff.baseAddress!.trim().isNotEmpty) ...[
                        Text(
                          staff.baseAddress!.trim(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (staff.formattedBaseCoordinates != null)
                        Text(
                          staff.formattedBaseCoordinates!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.mapStaffActiveTasksCount(staff.processingCount),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      final currentFilter = ref.read(mapFilterProvider);
                      ref.read(mapFilterProvider.notifier).state =
                          currentFilter.copyWith(assigneeId: staff.id);
                    },
                    icon: const Icon(Icons.filter_alt_outlined, size: 18),
                    label: Text(l10n.mapFilterByThisStaff),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => _sheetOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final reportsState = ref.watch(mapReportsProvider);
    final densityState = ref.watch(adminReportDensityProvider);
    final filter = ref.watch(mapFilterProvider);
    final showStaffStations = ref.watch(showStaffStationsProvider);
    // Keep mapStaffListProvider warm so staff stations render immediately
    ref.watch(mapStaffListProvider);

    int activeFilterCount = 0;
    if (filter.status != null && filter.status!.isNotEmpty) activeFilterCount++;
    if (filter.severity != null && filter.severity!.isNotEmpty) activeFilterCount++;
    if (filter.from != null || filter.to != null) activeFilterCount++;
    if (filter.assigneeId != null && filter.assigneeId!.isNotEmpty) activeFilterCount++;
    if (filter.timeframe != null &&
        filter.timeframe!.isNotEmpty &&
        filter.timeframe != 'all') {
      activeFilterCount++;
    }

    ref.listen(mapReportsProvider.select((s) => s.error), (previous, next) {
      if (next == null || previous != null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.mapLoadReportsFailed),
            action: SnackBarAction(
              label: l10n.retry,
              onPressed: _handleRefresh,
            ),
          ),
        );
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(l10n.spaceMap),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.mapRefresh,
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map luôn được giữ (không thay bằng spinner) → camera không bị reset khi tải lại
          Positioned.fill(
            child: platform_map.buildPlatformMap(
              context: context,
              reports: reportsState.reports,
              onMarkerTap: _onReportTap,
              onClusterTap: _showClusterSheet,
              onViewportChanged: _onViewportChanged,
              onStaffTap: _onStaffStationTap,
              initialFocus: widget.focus,
              onMapControllerCreated: (controller) {
                _platformMapController = controller;
              },
              onMapTap: () {
                // Chỉ tắt modal/sheet nếu đang mở một sheet, TUYỆT ĐỐI không pop AdminMapScreen
                if (_sheetOpen) {
                  Navigator.of(context).pop();
                  _sheetOpen = false;
                  return;
                }
                ref.read(adminMapControllerProvider.notifier).clearSelection();
              },
            ),
          ),

          if (reportsState.isLoading || (densityState.isEnabled && densityState.isLoading))
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),

          if (reportsState.truncated || (densityState.isEnabled && densityState.truncated))
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: PointerInterceptor(child: _ZoomInHint(label: l10n.mapZoomInForMore)),
              ),
            ),

          // Legends (Bottom Left: Density Legend above Status Legend)
          Positioned(
            bottom: 16,
            left: 12,
            child: PointerInterceptor(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Density Legend placed ABOVE the Status Legend
                  if (densityState.isEnabled) ...[
                    const MapDensityLegend(),
                    const SizedBox(height: 8),
                  ],
                  MapLegend(showStaffStations: showStaffStations),
                ],
              ),
            ),
          ),

          // Map Controls (Top Right: Hotspots, Settings, Staff Stations, My Location, Filter Reports)
          Builder(
            builder: (context) {
              final isWide = MediaQuery.sizeOf(context).width >= 900;
              final accelCount = ref.watch(spatialAnalyticsProvider).maybeWhen(
                    data: (res) => res.acceleratingHotspots,
                    orElse: () => 0,
                  );
              return MapControls(
                isDensityActive: densityState.isEnabled,
                onSettingsPressed: _showMapSettings,
                isStaffStationsActive: showStaffStations,
                onStaffStationsPressed: () {
                  ref.read(showStaffStationsProvider.notifier).state =
                      !showStaffStations;
                },
                onMyLocationPressed: () {
                  _platformMapController?.flyToUserLocation();
                },
                onFilterPressed: _showFilterSheet,
                isFilterActive: activeFilterCount > 0,
                activeFilterCount: activeFilterCount,
                onHotspotsPressed: () => _toggleHotspots(isWide),
                isHotspotsActive: _showHotspotsPanel,
                acceleratingHotspotsCount: accelCount,
              );
            },
          ),

          // Collapsible H3 Hotspots panel on wide screens
          if (_showHotspotsPanel && MediaQuery.sizeOf(context).width >= 900)
            Positioned(
              top: 16,
              left: 16,
              child: PointerInterceptor(
                child: SpatialHotspotPanel(
                  onClose: () => setState(() => _showHotspotsPanel = false),
                  onHotspotTap: _onHotspotSelected,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Gợi ý phóng to khi có nhiều report khớp bộ lọc hơn giới hạn tải.
class _ZoomInHint extends StatelessWidget {
  final String label;

  const _ZoomInHint({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerHigh,
      elevation: 2,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.zoom_in_rounded, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
