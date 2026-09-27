import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

import 'admin_map_controller.dart';
// Conditional import: web vs mobile
import 'admin_map_screen_mobile.dart'
    if (dart.library.html) 'admin_map_screen_web.dart'
    as platform_map;
import 'widgets/map_filter_panel.dart';
import 'widgets/map_legend.dart';
import 'widgets/map_report_sheet.dart';

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
      builder: (_) => MapReportSheet(
        report: report,
        onViewDetail: () {
          Navigator.of(context).pop();
          context.push('/reports/${report.id}');
        },
      ),
    ).whenComplete(() => _sheetOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final reportsAsync = ref.watch(mapReportsProvider);

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
            tooltip: l10n.map,
            onPressed: () => ref.read(mapReportsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map (platform-adaptive) — needs Positioned.fill for proper sizing
          Positioned.fill(
            child: reportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (reports) => platform_map.buildPlatformMap(
                context: context,
                reports: reports,
                onMarkerTap: _onReportTap,
                onMapTap: () {
                  // Only pop if there's a dialog/sheet open (canPop true)
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
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
