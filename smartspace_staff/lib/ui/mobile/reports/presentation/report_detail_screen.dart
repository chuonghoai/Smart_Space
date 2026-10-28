// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
import 'package:smartspace_staff/ui/shared/utils/open_in_google_maps.dart';

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

  Future<void> _openGoogleMaps(double lat, double lng) => openInGoogleMaps(context, lat, lng);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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

                        // Commission Details Banner / Card (Always at the top)
                        if (report.commissionAwarded == true || (report.baseCommission != null && report.baseCommission! > 0)) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.monetization_on_outlined,
                                      size: 18,
                                      color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.commissionBreakdown,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (report.baseCommission != null)
                                  Text(
                                    l10n.commissionReceived(NumberFormat('#,###', 'vi_VN').format(report.baseCommission!)),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                if (report.resolvedPenaltyDeductions.isNotEmpty) ...[
                                  for (final item in report.resolvedPenaltyDeductions) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.commissionPenaltyDeductionTurn(item.turn, NumberFormat('#,###', 'vi_VN').format(item.amount)),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ] else if (report.deductedCommission != null && report.deductedCommission! > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.commissionPenaltyDeducted(NumberFormat('#,###', 'vi_VN').format(report.deductedCommission!)),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                if (report.finalCommission != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.finalCommissionReceived(NumberFormat('#,###', 'vi_VN').format(report.finalCommission!)),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                                if (report.status == ReportStatus.processing) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.rehandlingNoExtraCommission,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ] else if (report.status == ReportStatus.processing &&
                            report.expectedCommission != null &&
                            report.expectedCommission! > 0) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2E7D32).withOpacity(0.18)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF66BB6A).withOpacity(0.4)
                                    : const Color(0xFFA5D6A7),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.monetization_on_outlined,
                                  color: isDark
                                      ? const Color(0xFF81C784)
                                      : const Color(0xFF2E7D32),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.commissionExpectedNotice(
                                      NumberFormat('#,###', 'vi_VN').format(report.expectedCommission!),
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? const Color(0xFFC8E6C9)
                                          : const Color(0xFF1B5E20),
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              report.userName?.isNotEmpty == true ? report.userName! : 'Unknown',
                                              style: theme.textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (report.userPhone != null && report.userPhone!.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                report.userPhone!,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Location Card
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
                                      Icons.location_on_outlined,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.locationSection,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            report.address?.isNotEmpty == true
                                                ? report.address!
                                                : l10n.noAddress,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (report.locationDescription?.isNotEmpty == true) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '${l10n.locationDescriptionLabel}: ${report.locationDescription!}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(left: 28.0),
                                  child: Text(
                                    '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Distance indicator
                                Consumer(
                                  builder: (context, ref, child) {
                                    final distanceAsync = ref.watch(reportDistanceProvider(widget.reportId));
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: distanceAsync.when(
                                        data: (distance) => Row(
                                          children: [
                                            Icon(
                                              Icons.near_me_outlined,
                                              size: 16,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              l10n.distanceFromYou((distance / 1000).toStringAsFixed(1), 'km'),
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        loading: () => Row(
                                          children: [
                                            const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n.calculatingDistance,
                                              style: theme.textTheme.bodySmall,
                                            ),
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
                                              style: TextStyle(
                                                color: theme.colorScheme.primary,
                                                decoration: TextDecoration.underline,
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                                // Map View
                                Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                                    ),
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
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openGoogleMaps(report.latitude, report.longitude),
                                    icon: const Icon(Icons.map_outlined, size: 18),
                                    label: Text(l10n.openInGoogleMaps),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Resolution Section (when processed or has resolution info)
                        if (report.status == ReportStatus.processed ||
                            report.resolvedNote != null ||
                            (report.resolvedImageUrls != null && report.resolvedImageUrls!.isNotEmpty)) ...[
                          const SizedBox(height: 16),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.green.withOpacity(0.4),
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
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 20,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n.resolutionInfo,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                      if (report.resolvedAt != null)
                                        Text(
                                          DateFormat('dd/MM/yyyy HH:mm').format(report.resolvedAt!),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  if (report.resolvedNote != null && report.resolvedNote!.isNotEmpty) ...[
                                    Text(
                                      l10n.resolutionNote,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      report.resolvedNote!,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (report.resolvedImageUrls != null && report.resolvedImageUrls!.isNotEmpty) ...[
                                    Text(
                                      l10n.resolutionImages,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 100,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: report.resolvedImageUrls!.length,
                                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                                        itemBuilder: (context, idx) {
                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => FullscreenImageViewer(
                                                    imageUrls: report.resolvedImageUrls!,
                                                    initialIndex: idx,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.network(
                                                report.resolvedImageUrls![idx],
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  width: 100,
                                                  height: 100,
                                                  color: theme.colorScheme.surfaceContainerHighest,
                                                  child: const Icon(Icons.broken_image),
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
                          ),
                        ],

                        // Citizen Review Section (when citizen review exists)
                        if (report.isReviewResolved != null) ...[
                          const SizedBox(height: 16),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: report.isReviewResolved == false
                                    ? theme.colorScheme.error.withOpacity(0.5)
                                    : Colors.amber.withOpacity(0.5),
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
                                        report.isReviewResolved == false
                                            ? Icons.report_problem_outlined
                                            : Icons.star_rounded,
                                        size: 20,
                                        color: report.isReviewResolved == false
                                            ? theme.colorScheme.error
                                            : Colors.amber,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          report.isReviewResolved == false
                                              ? l10n.citizenReviewUnresolved
                                              : l10n.citizenRating,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: report.isReviewResolved == false
                                                ? theme.colorScheme.error
                                                : Colors.amber.shade800,
                                          ),
                                        ),
                                      ),
                                      if (report.reviewedAt != null)
                                        Text(
                                          DateFormat('dd/MM/yyyy HH:mm').format(report.reviewedAt!),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  if (report.rating != null && report.rating! > 0) ...[
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < report.rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                                          color: Colors.amber,
                                          size: 20,
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (report.reviewNote != null && report.reviewNote!.isNotEmpty) ...[
                                    Text(
                                      report.isReviewResolved == false
                                          ? l10n.citizenReviewReason
                                          : l10n.resolutionNote,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      report.reviewNote!,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (report.reviewImageUrls != null && report.reviewImageUrls!.isNotEmpty) ...[
                                    Text(
                                      l10n.citizenReviewPhotos,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 100,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: report.reviewImageUrls!.length,
                                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                                        itemBuilder: (context, idx) {
                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => FullscreenImageViewer(
                                                    imageUrls: report.reviewImageUrls!,
                                                    initialIndex: idx,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.network(
                                                report.reviewImageUrls![idx],
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  width: 100,
                                                  height: 100,
                                                  color: theme.colorScheme.surfaceContainerHighest,
                                                  child: const Icon(Icons.broken_image),
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
                          ),
                        ],
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

