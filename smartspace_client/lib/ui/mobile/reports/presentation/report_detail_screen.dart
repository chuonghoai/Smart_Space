import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/report_detail_provider.dart';
import 'package:smartspace_client/features/reports/utils/report_status_ext.dart';
import 'package:smartspace_client/features/reports/utils/report_severity_ext.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/reports/presentation/widgets/fullscreen_image_viewer.dart';
import 'package:smartspace_client/ui/mobile/reports/presentation/widgets/report_review_dialog.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> with WidgetsBindingObserver {
  DateTime? _lastAutoShownResolvedAt;

  void _openReviewDialog() {
    ReportReviewDialog.show(
      context,
      reportId: widget.reportId,
      onReviewSubmitted: () {
        ref.read(reportDetailProvider(widget.reportId).notifier).refresh();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportDetails),
        actions: [
          if (reportAsyncValue.valueOrNull != null &&
              reportAsyncValue.valueOrNull!.status == ReportStatus.processed &&
              !reportAsyncValue.valueOrNull!.hasReviewed)
            TextButton.icon(
              onPressed: _openReviewDialog,
              icon: const Icon(Icons.star_outline_rounded, size: 20),
              label: Text(l10n.reviewReport),
            ),
        ],
      ),
      body: reportAsyncValue.when(
        data: (report) {
          if (report.status == ReportStatus.processed &&
              !report.hasReviewed &&
              _lastAutoShownResolvedAt != report.resolvedAt) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _lastAutoShownResolvedAt != report.resolvedAt) {
                _lastAutoShownResolvedAt = report.resolvedAt;
                _openReviewDialog();
              }
            });
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(reportDetailProvider(widget.reportId).notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Slider ảnh
                  if (report.imageUrls.isNotEmpty)
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
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

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags (Status, Severity, Time)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                report.status.getLocalizedText(l10n),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: report.status.getColor(context),
                            ),
                            if (report.isReviewResolved == false)
                              Chip(
                                avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white),
                                label: Text(
                                  l10n.unsatisfactoryBadge,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: const Color(0xFFD97706),
                              ),
                            Chip(
                              label: Text(
                                report.severity.getLocalizedText(l10n),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: report.severity.getColor(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.createdAtLabel}: ${DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),

                        // Info
                        Text(
                          report.title,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),

                        if (report.assignedStaffId != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.assignedStaff,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: report.assignedStaffAvatarUrl != null && report.assignedStaffAvatarUrl!.isNotEmpty
                                          ? NetworkImage(report.assignedStaffAvatarUrl!)
                                          : null,
                                      child: (report.assignedStaffAvatarUrl == null || report.assignedStaffAvatarUrl!.isEmpty)
                                          ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            report.assignedStaffName ?? 'Unknown',
                                            style: theme.textTheme.titleMedium,
                                          ),
                                          if (report.isReviewResolved == true && report.rating != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                ...List.generate(
                                                  5,
                                                  (i) => Icon(
                                                    i < report.rating!
                                                        ? Icons.star_rounded
                                                        : Icons.star_outline_rounded,
                                                    size: 16,
                                                    color: Colors.amber,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${report.rating}/5',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Unresolved feedback section
                        if (report.isReviewResolved == false) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer.withAlpha(50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.error.withAlpha(100)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.report_problem_outlined, color: theme.colorScheme.error, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.unresolvedReviewTitle,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                                if (report.reviewNote != null && report.reviewNote!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    report.reviewNote!,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                                if (report.reviewImageUrls.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 180,
                                    child: PageView.builder(
                                      itemCount: report.reviewImageUrls.length,
                                      itemBuilder: (context, idx) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => FullscreenImageViewer(
                                                  imageUrls: report.reviewImageUrls,
                                                  initialIndex: idx,
                                                ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              report.reviewImageUrls[idx],
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image)),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Map & Distance
                        Consumer(
                          builder: (context, ref, child) {
                            final distanceAsync = ref.watch(reportDistanceProvider(widget.reportId));
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: distanceAsync.when(
                                data: (distance) => Text(
                                  l10n.distanceFromYou((distance / 1000).toStringAsFixed(1)),
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
    );
  }
}

