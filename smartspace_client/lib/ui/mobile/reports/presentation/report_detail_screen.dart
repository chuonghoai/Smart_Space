// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_shared/features/map/models/map_focus_target.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';
import 'package:smartspace_client/features/reports/models/report_detail_model.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/current_user_provider.dart';
import 'package:smartspace_client/features/reports/providers/report_detail_provider.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';
import 'package:smartspace_client/features/reports/utils/report_status_ext.dart';
import 'package:smartspace_client/features/reports/utils/report_severity_ext.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/mobile/reports/presentation/widgets/fullscreen_image_viewer.dart';
import 'package:smartspace_client/ui/mobile/reports/presentation/widgets/report_review_dialog.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen>
    with WidgetsBindingObserver {
  DateTime? _lastAutoShownResolvedAt;
  int _currentImageIndex = 0;

  void _openReviewDialog() {
    ReportReviewDialog.show(
      context,
      reportId: widget.reportId,
      onReviewSubmitted: () {
        ref.read(reportDetailProvider(widget.reportId).notifier).refresh();
      },
    );
  }

  Future<void> _handleEditReport(ReportDetailModel report) async {
    final l10n = AppLocalizations.of(context)!;

    // Strict constraint: only pending reports can be edited
    if (report.status != ReportStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.editReportOnlyPending)),
      );
      return;
    }

    final updated = await context.push<bool>(
      RouterPath.createReport,
      extra: report,
    );
    if (updated == true && mounted) {
      ref.read(reportDetailProvider(widget.reportId).notifier).refresh();
    }
  }

  Future<void> _handleCancelReport(ReportDetailModel report) async {
    final l10n = AppLocalizations.of(context)!;

    // Strict constraint: only pending reports can be cancelled
    if (report.status != ReportStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cancelReportOnlyPending)),
      );
      return;
    }

    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelReportConfirmTitle),
        content: Text(l10n.cancelReportConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.closeButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.cancelReport),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final res = await reportService.cancelReport(report.id);
      if (!mounted) return;
      Navigator.of(context).pop(); // pop loading

      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cancelReportSuccess),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(reportDetailProvider(widget.reportId).notifier).refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty ? res.message : l10n.genericError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.locationServiceDisabledError,
            ),
          ),
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .locationPermissionDeniedForeverError,
            ),
          ),
        );
      }
      await Geolocator.openAppSettings();
      return;
    }

    // Refresh provider to get distance
    ref.invalidate(reportDistanceProvider(widget.reportId));
  }

  /// Mở bản đồ Mapbox trong app, focus vào report này.
  void _openOnMap(double lat, double lng) {
    context.push(RouterPath.mapWithFocus(
      MapFocusTarget(reportId: widget.reportId, latitude: lat, longitude: lng),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reportAsyncValue = ref.watch(reportDetailProvider(widget.reportId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUserId = currentUserAsync.valueOrNull?.id;
    final detailReport = reportAsyncValue.valueOrNull;
    final isMyReport = currentUserId != null &&
        detailReport != null &&
        detailReport.userId != null &&
        currentUserId == detailReport.userId;
    final canEdit = isMyReport && detailReport.status == ReportStatus.pending;
    final canCancel = isMyReport && detailReport.status == ReportStatus.pending;
    final hasMyReportActions = canEdit || canCancel;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.reportDetails,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (detailReport != null &&
              detailReport.status == ReportStatus.processed &&
              !detailReport.hasReviewed)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilledButton.tonalIcon(
                onPressed: _openReviewDialog,
                icon: const Icon(Icons.star_rounded, size: 18),
                label: Text(l10n.reviewReport),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          if (hasMyReportActions)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'edit') {
                  _handleEditReport(detailReport);
                } else if (val == 'cancel') {
                  _handleCancelReport(detailReport);
                }
              },
              itemBuilder: (ctx) => [
                if (canEdit)
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.editReport),
                      ],
                    ),
                  ),
                if (canCancel)
                  PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.cancelReport,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
              ],
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

          final statusColor = report.status.getColor(context);
          final severityColor = report.severity.getColor(context);

          return RefreshIndicator(
            onRefresh: () => ref
                .read(reportDetailProvider(widget.reportId).notifier)
                .refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery with Counter & Dots
                  if (report.imageUrls.isNotEmpty)
                    Stack(
                      children: [
                        SizedBox(
                          height: 260,
                          width: double.infinity,
                          child: PageView.builder(
                            itemCount: report.imageUrls.length,
                            onPageChanged: (idx) {
                              setState(() => _currentImageIndex = idx);
                            },
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
                                child: Container(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: Image.network(
                                    report.imageUrls[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 48,
                                        color: theme
                                            .colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Image Counter Pill
                        if (report.imageUrls.length > 1)
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.photo_library_outlined,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${_currentImageIndex + 1}/${report.imageUrls.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Bottom Pagination Dots
                        if (report.imageUrls.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                report.imageUrls.length,
                                (idx) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: _currentImageIndex == idx ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == idx
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags Row (Status, Unresolved, Severity)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Status Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                report.status.getLocalizedText(l10n),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Unsatisfactory badge
                            if (report.isReviewResolved == false)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFD97706)
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 14,
                                      color: Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.unsatisfactoryBadge,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: const Color(0xFFD97706),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Severity Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: severityColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: severityColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                report.severity.getLocalizedText(l10n),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: severityColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // My Report Badge ("Bạn là người tạo phản ánh này")
                            if (isMyReport)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_pin_circle_outlined,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.youCreatedThisReport,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Created date
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${l10n.createdAtLabel}: ${DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title & Description Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                report.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.9),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Assigned Staff Card
                        if (report.assignedStaffId != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_ind_outlined,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.assignedStaff,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: (report.assignedStaffAvatarUrl !=
                                                    null &&
                                                report.assignedStaffAvatarUrl!
                                                    .isNotEmpty)
                                            ? Image.network(
                                                report
                                                    .assignedStaffAvatarUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) => Icon(
                                                  Icons.person,
                                                  color: theme
                                                      .colorScheme.primary,
                                                ),
                                              )
                                            : Icon(
                                                Icons.person,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            report.assignedStaffName ??
                                                'Unknown',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (report.isReviewResolved == true &&
                                              report.rating != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                ...List.generate(
                                                  5,
                                                  (i) => Icon(
                                                    i < report.rating!
                                                        ? Icons.star_rounded
                                                        : Icons
                                                            .star_outline_rounded,
                                                    size: 16,
                                                    color: Colors.amber,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${report.rating}/5',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: theme.colorScheme
                                                        .onSurfaceVariant,
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
                          const SizedBox(height: 16),
                        ],

                        // Unresolved feedback section
                        if (report.isReviewResolved == false) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer
                                  .withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.error
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.report_problem_outlined,
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.unresolvedReviewTitle,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                                if (report.reviewNote != null &&
                                    report.reviewNote!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    report.reviewNote!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                                if (report.reviewImageUrls.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 180,
                                    child: PageView.builder(
                                      itemCount:
                                          report.reviewImageUrls.length,
                                      itemBuilder: (context, idx) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    FullscreenImageViewer(
                                                  imageUrls:
                                                      report.reviewImageUrls,
                                                  initialIndex: idx,
                                                ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              report.reviewImageUrls[idx],
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => Center(
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                  color:
                                                      theme.colorScheme.error,
                                                ),
                                              ),
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
                          const SizedBox(height: 16),
                        ],

                        // Location Card
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.locationSection,
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Distance indicator in header
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final distanceAsync = ref.watch(
                                        reportDistanceProvider(
                                          widget.reportId,
                                        ),
                                      );
                                      return distanceAsync.when(
                                        data: (distance) => Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.near_me_outlined,
                                                size: 13,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                l10n.distanceFromYou(
                                                  (distance / 1000)
                                                      .toStringAsFixed(1),
                                                ),
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        loading: () => const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        error: (err, stack) {
                                          String errorMsg = l10n
                                              .turnOnLocationToViewDistance;
                                          if (err == 'LOCATION_DISABLED') {
                                            errorMsg = l10n
                                                .locationServiceDisabledError;
                                          } else if (err ==
                                              'PERMISSION_DENIED') {
                                            errorMsg = l10n
                                                .locationPermissionDeniedForeverError;
                                          }

                                          return InkWell(
                                            onTap:
                                                _requestLocationPermission,
                                            child: Text(
                                              errorMsg,
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                                decoration:
                                                    TextDecoration.underline,
                                                fontSize: 11,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),

                              // Address content
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.place_rounded,
                                    size: 20,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          report.address?.isNotEmpty == true
                                              ? report.address!
                                              : l10n.noAddress,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (report.locationDescription
                                                ?.isNotEmpty ==
                                            true) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '${l10n.locationDescriptionLabel}: ${report.locationDescription!}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 28.0),
                                child: Text(
                                  '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Map View
                              Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Stack(
                                    children: [
                                      FlutterMap(
                                        options: MapOptions(
                                          initialCenter: LatLng(
                                            report.latitude,
                                            report.longitude,
                                          ),
                                          initialZoom: 15.0,
                                          interactionOptions:
                                              const InteractionOptions(
                                            flags: InteractiveFlag.none,
                                          ),
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate:
                                                'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                                          ),
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: LatLng(
                                                  report.latitude,
                                                  report.longitude,
                                                ),
                                                width: 36,
                                                height: 36,
                                                child: Icon(
                                                  Icons.location_on,
                                                  color:
                                                      theme.colorScheme.error,
                                                  size: 36,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Positioned.fill(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _openOnMap(
                                              report.latitude,
                                              report.longitude,
                                            ),
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
                                child: OutlinedButton.icon(
                                  onPressed: () => _openOnMap(
                                    report.latitude,
                                    report.longitude,
                                  ),
                                  icon: const Icon(
                                    Icons.map_outlined,
                                    size: 18,
                                  ),
                                  label: Text(l10n.viewOnMap),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.errorOccurred(error.toString()),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(reportDetailProvider(widget.reportId).notifier)
                      .refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retryButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
