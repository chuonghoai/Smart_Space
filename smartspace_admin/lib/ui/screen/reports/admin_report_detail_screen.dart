import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/features/reports/application/report_providers.dart';
import 'package:smartspace_admin/features/reports/models/report_detail_model.dart';
import 'package:smartspace_admin/features/reports/models/staff_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const AdminReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  ConsumerState<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState
    extends ConsumerState<AdminReportDetailScreen> {
  int _currentImageIndex = 0;
  StaffModel? _selectedStaff;
  String _selectedSeverity = 'low';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reportAsync = ref.watch(reportDetailProvider(widget.reportId));
    final assignState = ref.watch(reportAssignProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.reportDetailTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: reportAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    ref
                        .read(reportDetailProvider(widget.reportId).notifier)
                        .refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (report) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(reportDetailProvider(widget.reportId).notifier).refresh();
          },
          child: _buildContent(context, report, l10n, theme, assignState),
        ),
      ),
      bottomNavigationBar: _buildBottomActionButton(context, l10n, theme, assignState, reportAsync.valueOrNull),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ReportDetailModel report,
    AppLocalizations l10n,
    ThemeData theme,
    ReportAssignState assignState,
  ) {
    final isPending = report.status.toUpperCase() == 'PENDING';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Image Slider / Single Image Header (from image_urls list)
          _buildImageSection(context, report.images, l10n),
          const SizedBox(height: 16),

          // 2. Status & Severity Dual Cards Header
          _buildStatusAndSeveritySection(context, report, l10n, theme),
          const SizedBox(height: 16),

          // 3. Report Info Card (Title, Description, CreatedAt)
          _buildReportInfoCard(context, report, l10n, theme),
          const SizedBox(height: 16),

          // 4. Reporter Card
          _buildReporterCard(context, report, l10n, theme),
          const SizedBox(height: 16),

          // 5. Location Card
          _buildLocationCard(context, report, l10n, theme),
          const SizedBox(height: 16),

          // 6. Assign Staff & Severity 2-Column Section
          if (isPending)
            _buildAssignStaffTwoColumnSection(context, report, l10n, theme)
          else
            _buildAssignedStaffTwoColumnCard(context, report, l10n, theme),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, List<String> images, AppLocalizations l10n) {
    final theme = Theme.of(context);

    if (images.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 44,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noImageAvailable,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: () => _openFullscreenImage(images, 0),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: AppNetworkImage(
              url: images.first,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    // Multiple images slider
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openFullscreenImage(images, index),
                  child: AppNetworkImage(
                    url: images[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
            // Page Indicator badge
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreenImage(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(
          imageUrls: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildStatusAndSeveritySection(
    BuildContext context,
    ReportDetailModel report,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final statusColor = _getStatusColor(report.status, theme);
    final statusText = _getStatusText(report.status, l10n);
    final hasSeverity = report.severity != null && report.severity!.isNotEmpty;
    final severityColor = hasSeverity ? _getSeverityColor(report.severity!, theme) : theme.colorScheme.outline;
    final severityText = hasSeverity ? _getSeverityText(report.severity!, l10n) : '---';

    return Row(
      children: [
        // 1. Status Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
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
        const SizedBox(width: 12),

        // 2. Severity Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
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
                    Text(
                      l10n.severitySection,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: severityColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: severityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          severityText,
                          style: TextStyle(
                            color: severityColor,
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
    );
  }

  Widget _buildReportInfoCard(
    BuildContext context,
    ReportDetailModel report,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final formattedDate =
        DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt.toLocal());

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.reportInfoSection,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              report.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              report.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${l10n.createdAtLabel}: $formattedDate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReporterCard(
    BuildContext context,
    ReportDetailModel report,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                  l10n.reporterInfoSection,
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
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
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
            const Divider(height: 20),
            Row(
              children: [
                AppNetworkImage(
                  url: report.userAvatarUrl,
                  width: 44,
                  height: 44,
                  isCircle: true,
                  errorWidget: CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (report.userName?.isNotEmpty == true)
                          ? report.userName![0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.userName?.isNotEmpty == true
                            ? report.userName!
                            : l10n.user,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (report.userPhone != null &&
                          report.userPhone!.isNotEmpty)
                        Text(
                          report.userPhone!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (report.isAnonymous) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.anonymousAdminNotice,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    ReportDetailModel report,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final hasCoords = report.latitude != null && report.longitude != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.address?.isNotEmpty == true
                        ? report.address!
                        : l10n.noAddress,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (hasCoords) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 26.0),
                child: Text(
                  '${report.latitude!.toStringAsFixed(6)}, ${report.longitude!.toStringAsFixed(6)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openMaps(report.latitude!, report.longitude!, l10n),
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
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(double lat, double lng, AppLocalizations l10n) async {
    final Uri uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallbackLaunched = await launchUrl(uri);
        if (!fallbackLaunched) {
          Toast.show(ToastType.warning, l10n.cannotOpenMaps);
        }
      }
    } catch (_) {
      Toast.show(ToastType.warning, l10n.cannotOpenMaps);
    }
  }

  /// 2-Column Section for Assigning Staff (Left Column) & Severity Selection (Right Column)
  Widget _buildAssignStaffTwoColumnSection(
    BuildContext context,
    ReportDetailModel report,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final staffsAsync = ref.watch(staffsProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                  Icons.assignment_ind_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.assignStaffSection,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // 2-Column layout with IntrinsicHeight
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cột trái: Nhân viên (flex 6)
                  Expanded(
                    flex: 6,
                    child: _buildStaffSelectionCard(context, staffsAsync, l10n, theme),
                  ),
                  const SizedBox(width: 12),
                  // Cột phải: Mức độ nghiêm trọng (flex 5)
                  Expanded(
                    flex: 5,
                    child: _buildSeverityVerticalColumn(context, l10n, theme),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffSelectionCard(
    BuildContext context,
    AsyncValue<List<StaffModel>> staffsAsync,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return staffsAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            e.toString(),
            style: TextStyle(color: theme.colorScheme.error, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (staffs) {
        if (_selectedStaff == null) {
          // Placeholder khi chưa chọn nhân viên: Chiều cao tối thiểu 200px
          return InkWell(
            onTap: () => _showStaffPickerBottomSheet(context, staffs, l10n, theme),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                    child: Icon(
                      Icons.person_add_alt_1_outlined,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.selectStaffPrompt,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }

        // Đã chọn nhân viên: Chiều cao tối thiểu 200px đồng bộ với cột phải
        return InkWell(
          onTap: () => _showStaffPickerBottomSheet(context, staffs, l10n, theme),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                AppNetworkImage(
                  url: _selectedStaff!.avatarUrl,
                  width: 46,
                  height: 46,
                  isCircle: true,
                  errorWidget: CircleAvatar(
                    radius: 23,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      _selectedStaff!.fullName.isNotEmpty
                          ? _selectedStaff!.fullName[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Name
                Text(
                  _selectedStaff!.fullName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Email (hiển thị dài nhất có thể, xuống tối đa 2 dòng hoặc ellipsis)
                Text(
                  _selectedStaff!.email,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Phone
                if (_selectedStaff!.phoneNumber != null &&
                    _selectedStaff!.phoneNumber!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          _selectedStaff!.phoneNumber!,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 6),

                // Change staff chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sync_alt_rounded,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.changeStaff,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeverityVerticalColumn(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSeverityFullWidthButton('low', l10n.severityLow, Colors.green, theme),
        const SizedBox(height: 8),
        _buildSeverityFullWidthButton('medium', l10n.severityMedium, Colors.blue, theme),
        const SizedBox(height: 8),
        _buildSeverityFullWidthButton('high', l10n.severityHigh, Colors.orange, theme),
        const SizedBox(height: 8),
        _buildSeverityFullWidthButton('critical', l10n.severityCritical, Colors.red, theme),
      ],
    );
  }

  Widget _buildSeverityFullWidthButton(
    String key,
    String label,
    Color color,
    ThemeData theme,
  ) {
    final isSelected = _selectedSeverity == key;

    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        width: double.infinity,
        child: Material(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? color : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedSeverity = key;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? color : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showStaffPickerBottomSheet(
    BuildContext context,
    List<StaffModel> staffs,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  l10n.selectStaffPrompt,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: staffs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final staff = staffs[index];
                    final isSelected = _selectedStaff?.id == staff.id;

                    return ListTile(
                      leading: AppNetworkImage(
                        url: staff.avatarUrl,
                        width: 40,
                        height: 40,
                        isCircle: true,
                        errorWidget: CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            staff.fullName.isNotEmpty
                                ? staff.fullName[0].toUpperCase()
                                : 'S',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        staff.fullName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${staff.email}${staff.phoneNumber != null ? ' • ${staff.phoneNumber}' : ''}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedStaff = staff;
                        });
                        Navigator.of(bottomSheetContext).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignedStaffTwoColumnCard(
    BuildContext context,
    ReportDetailModel report,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                  Icons.engineering_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.assignedStaffInfo,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                AppNetworkImage(
                  url: report.assignedStaffAvatarUrl,
                  width: 44,
                  height: 44,
                  isCircle: true,
                  errorWidget: CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      report.assignedStaffName?.isNotEmpty == true
                          ? report.assignedStaffName![0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.assignedStaffName?.isNotEmpty == true
                            ? report.assignedStaffName!
                            : l10n.staff,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (report.assignedStaffEmail != null &&
                          report.assignedStaffEmail!.isNotEmpty)
                        Text(
                          report.assignedStaffEmail!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (report.assignedStaffPhone != null &&
                          report.assignedStaffPhone!.isNotEmpty)
                        Text(
                          report.assignedStaffPhone!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
    );
  }

  /// Bottom action button (Xử lý phản ánh):
  /// - Only shown when report is PENDING and _selectedStaff != null (per user requirement to avoid clutter).
  Widget? _buildBottomActionButton(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ReportAssignState assignState,
    ReportDetailModel? report,
  ) {
    if (report == null) return null;
    if (report.status.toUpperCase() != 'PENDING') return null;

    // Requirement: Hide button if disabled (_selectedStaff == null)
    if (_selectedStaff == null) {
      return null;
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -2),
              blurRadius: 10,
            ),
          ],
        ),
        child: FilledButton(
          onPressed: assignState.isLoading
              ? null
              : () => _submitAssign(context, l10n),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: assignState.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  l10n.processReportButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _submitAssign(BuildContext context, AppLocalizations l10n) async {
    if (_selectedStaff == null) return;

    final success = await ref.read(reportAssignProvider.notifier).assignReport(
          reportId: widget.reportId,
          staffId: _selectedStaff!.id,
          severity: _selectedSeverity,
        );

    if (mounted) {
      if (success) {
        Toast.show(ToastType.success, l10n.assignSuccessMessage);
      } else {
        Toast.show(ToastType.error, l10n.assignFailedMessage);
      }
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return theme.colorScheme.primary;
      case 'RESOLVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return theme.colorScheme.outline;
    }
  }

  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return l10n.reportStatusPending;
      case 'PROCESSING':
        return l10n.reportStatusProcessing;
      case 'RESOLVED':
        return l10n.reportStatusProcessed;
      case 'REJECTED':
        return l10n.reportStatusRejected;
      default:
        return l10n.reportStatusUnknown;
    }
  }

  Color _getSeverityColor(String severity, ThemeData theme) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _getSeverityText(String severity, AppLocalizations l10n) {
    switch (severity.toLowerCase()) {
      case 'low':
        return l10n.severityLow;
      case 'medium':
        return l10n.severityMedium;
      case 'high':
        return l10n.severityHigh;
      case 'critical':
        return l10n.severityCritical;
      default:
        return severity;
    }
  }
}
