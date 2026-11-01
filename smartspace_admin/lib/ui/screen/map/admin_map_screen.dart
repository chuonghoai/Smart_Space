import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:mobile_shared/features/map/models/map_focus_target.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';

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
    ref.read(adminMapControllerProvider.notifier).refresh();
    await _platformMapController?.refreshViewport();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final reportsState = ref.watch(mapReportsProvider);
    final densityState = ref.watch(adminReportDensityProvider);
    final filter = ref.watch(mapFilterProvider);

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
                  const MapLegend(),
                ],
              ),
            ),
          ),

          // Map Controls (Top Right: Settings, My Location, Filter Reports)
          MapControls(
            isDensityActive: densityState.isEnabled,
            onSettingsPressed: _showMapSettings,
            onMyLocationPressed: () {
              _platformMapController?.flyToUserLocation();
            },
            onFilterPressed: _showFilterSheet,
            isFilterActive: activeFilterCount > 0,
            activeFilterCount: activeFilterCount,
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
