import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'widgets/map_cluster_sheet.dart';
import 'widgets/map_filter_panel.dart';
import 'widgets/map_legend.dart';
import 'widgets/map_report_sheet.dart';
import 'widgets/map_quick_assign_sheet.dart';

class AdminMapScreen extends ConsumerStatefulWidget {
  const AdminMapScreen({super.key});

  @override
  ConsumerState<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends ConsumerState<AdminMapScreen> {
  bool _sheetOpen = false;

  void _onReportTap(MapReportModel report) {
    ref.read(adminMapControllerProvider.notifier).selectReport(report);

    // Close existing sheet before opening new one
    if (_sheetOpen) {
      Navigator.of(context).pop();
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PointerInterceptor(
        child: MapQuickAssignSheet(
          report: report,
          onAssigned: () => ref.read(adminMapControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }

  /// Cluster không tách được nữa → danh sách; bấm một dòng → sheet chi tiết (có phân công).
  void _showClusterSheet(List<MapReportModel> reports) {
    if (_sheetOpen) {
      Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final reportsState = ref.watch(mapReportsProvider);

    ref.listen(mapReportsProvider.select((s) => s.error), (previous, next) {
      if (next == null || previous != null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.mapLoadReportsFailed),
            action: SnackBarAction(
              label: l10n.retry,
              onPressed: () => ref.read(adminMapControllerProvider.notifier).refresh(),
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
            onPressed: () => ref.read(adminMapControllerProvider.notifier).refresh(),
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
              onViewportChanged: (bounds) =>
                  ref.read(adminMapControllerProvider.notifier).onViewportChanged(bounds),
              onMapTap: () {
                // Only pop if there's a dialog/sheet open (canPop true)
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),

          if (reportsState.isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),

          if (reportsState.truncated)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: PointerInterceptor(child: _ZoomInHint(label: l10n.mapZoomInForMore)),
              ),
            ),

          // Legend
          const MapLegend(),

          // Filter Panel (Top Left)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: PointerInterceptor(child: const MapFilterPanel()),
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
