// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/providers/report_detail_provider.dart';
import 'package:smartspace_staff/features/reports/services/handle_report_background_service.dart';
import 'package:smartspace_staff/features/reports/utils/report_status_ext.dart';
import 'package:smartspace_staff/features/reports/utils/report_severity_ext.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/ui/mobile/reports/presentation/widgets/fullscreen_image_viewer.dart';
import 'package:smartspace_staff/ui/mobile/reports/presentation/widgets/handling_progress_dialog.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> with WidgetsBindingObserver {
  late final PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Geolocator.isLocationServiceEnabled().then((enabled) {
        if (enabled && mounted) {
          ref.invalidate(reportDistanceProvider(widget.reportId));
        }
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.locationServiceDisabledError)),
        );
      }
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.locationPermissionDeniedForeverError)),
        );
      }
      await Geolocator.openAppSettings();
      return;
    }

    // Refresh provider to get distance
    ref.invalidate(reportDistanceProvider(widget.reportId));
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cannotOpenGoogleMapsError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reportAsyncValue = ref.watch(reportDetailProvider(widget.reportId));
    final reportData = reportAsyncValue.asData?.value;
    final isHandling = handleReportBackgroundService.isHandling(widget.reportId);
    final canHandle = reportData != null &&
        reportData.status != ReportStatus.processed &&
        reportData.status != ReportStatus.rejected &&
        !isHandling;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportDetails),
        actions: [
          if (canHandle)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  final result = await context.push('/reports/${widget.reportId}/handle');
                  if (context.mounted && result == true) {
                    HandlingProgressDialog.show(context, widget.reportId);
                  }
                },
                icon: const Icon(Icons.build_circle_outlined, size: 18),
                label: Text(l10n.processReportAction),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          ListenableBuilder(
            listenable: handleReportBackgroundService,
            builder: (context, _) {
              final task =
                  handleReportBackgroundService.getTask(widget.reportId);
              if (task == null || task.status != HandleTaskStatus.inProgress) {
                return const SizedBox.shrink();
              }
              return Material(
                color: theme.colorScheme.primaryContainer,
                child: InkWell(
                  onTap: () =>
                      HandlingProgressDialog.show(context, widget.reportId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: task.totalSteps > 0
                                ? (task.currentStep / task.totalSteps)
                                : null,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${l10n.submittingReportBackgroundTitle} (${task.currentStep}/${task.totalSteps})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: reportAsyncValue.when(
        data: (report) {
          return RefreshIndicator(
            onRefresh: () => ref.read(reportDetailProvider(widget.reportId).notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Slider ảnh
                  if (report.imageUrls.isNotEmpty)
                    if (report.imageUrls.length == 1)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FullscreenImageViewer(
                                imageUrls: report.imageUrls,
                                initialIndex: 0,
                              ),
                            ),
                          );
                        },
                        child: Image.network(
                          report.imageUrls.first,
                          fit: BoxFit.cover,
                          height: 250,
                          width: double.infinity,
                          errorBuilder: (_, _, _) => const SizedBox(height: 250, child: Center(child: Icon(Icons.broken_image, size: 50))),
                        ),
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            height: 250,
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemCount: report.imageUrls.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => FullscreenImageViewer(
                                          imageUrls: report.imageUrls,
                                          initialIndex: index,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Image.network(
                                    report.imageUrls[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image, size: 50)),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () {
                                  _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                },
                              ),
                              Text(
                                '${_currentImageIndex + 1} / ${report.imageUrls.length}',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () {
                                  _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rehandling Notice Banner (only when rehandling is requested)
                        if (report.status == ReportStatus.processing && report.isReviewResolved == false) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.deepOrange.withOpacity(0.35)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.replay_rounded, color: Colors.deepOrange, size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.rehandlingBadge,
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.rehandlingNotice,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Status & Severity Dual Cards
                        Row(
                          children: [
                            // Status Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 15,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          l10n.statusLabel,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: report.status.getColor(context).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: report.status.getColor(context).withOpacity(0.35)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: BoxDecoration(
                                                  color: report.status.getColor(context),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                report.status.getLocalizedText(l10n),
                                                style: TextStyle(
                                                  color: report.status.getColor(context),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (report.status == ReportStatus.processing && report.isReviewResolved == false)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.deepOrange.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Colors.deepOrange.withOpacity(0.4)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.replay_rounded, size: 12, color: Colors.deepOrange),
                                                const SizedBox(width: 4),
                                                Text(
                                                  l10n.rehandlingBadge,
                                                  style: const TextStyle(
                                                    color: Colors.deepOrange,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Severity Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          size: 15,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            l10n.severityLabel,
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: report.severity.getColor(context).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: report.severity.getColor(context).withOpacity(0.35)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: report.severity.getColor(context),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              report.severity.getLocalizedText(l10n),
                                              style: TextStyle(
                                                color: report.severity.getColor(context),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title & Desc
                        Text(
                          report.title,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              '${l10n.createdAtLabel}: ${DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Reporter Info
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          color: theme.colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      report.isAnonymous ? l10n.anonymousUser : l10n.reporter,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    if (report.isAnonymous) ...[
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.errorContainer.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.visibility_off_outlined,
                                              size: 13,
                                              color: theme.colorScheme.onErrorContainer,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              l10n.anonymousUser,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onErrorContainer,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (!report.isAnonymous) ...[
                                  const Divider(height: 20),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundImage: report.userAvatarUrl != null && report.userAvatarUrl!.isNotEmpty
                                            ? NetworkImage(report.userAvatarUrl!)
                                            : null,
                                        child: (report.userAvatarUrl == null || report.userAvatarUrl!.isEmpty)
                                            ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          report.userName?.isNotEmpty == true ? report.userName! : 'Unknown',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Map & Distance
                        Consumer(
                          builder: (context, ref, child) {
                            final distanceAsync = ref.watch(reportDistanceProvider(widget.reportId));
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: distanceAsync.when(
                                data: (distance) => Text(
                                  l10n.distanceFromYou((distance / 1000).toStringAsFixed(1), 'km'),
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                loading: () => Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(l10n.calculatingDistance),
                                  ],
                                ),
                                error: (err, stack) {
                                  String errorMsg = l10n.turnOnLocationToViewDistance;
                                  if (err == 'LOCATION_DISABLED') {
                                    errorMsg = l10n.locationServiceDisabledError;
                                  } else if (err == 'PERMISSION_DENIED') {
                                    errorMsg = l10n.locationPermissionDeniedForeverError;
                                  }
                                  
                                  return InkWell(
                                    onTap: _requestLocationPermission,
                                    child: Text(
                                      errorMsg,
                                      style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),

                        // Map View
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                FlutterMap(
                                  options: MapOptions(
                                    initialCenter: LatLng(report.latitude, report.longitude),
                                    initialZoom: 15.0,
                                    interactionOptions: const InteractionOptions(
                                      flags: InteractiveFlag.none,
                                    ),
                                  ),
                                  children: [
                                    TileLayer(urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}'),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(report.latitude, report.longitude),
                                          width: 40,
                                          height: 40,
                                          child: Icon(Icons.location_on, color: theme.colorScheme.error, size: 40),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Cover the map to intercept taps if we want them to open google maps on tap directly
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _openGoogleMaps(report.latitude, report.longitude),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openGoogleMaps(report.latitude, report.longitude),
                            icon: const Icon(Icons.map),
                            label: Text(l10n.openInGoogleMaps),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.errorOccurred(error.toString()), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(reportDetailProvider(widget.reportId).notifier).refresh(),
                child: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      ),
          ),
        ],
      ),
    );
  }
}

