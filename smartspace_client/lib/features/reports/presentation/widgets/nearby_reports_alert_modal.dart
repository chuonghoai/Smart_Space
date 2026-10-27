// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_client/features/reports/models/nearby_reports_alert_model.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';

class NearbyReportsAlertModal extends StatefulWidget {
  final NearbyReportsAlertResponse alertData;

  const NearbyReportsAlertModal({
    super.key,
    required this.alertData,
  });

  static bool _isShowing = false;

  static Future<void> show(BuildContext context, NearbyReportsAlertResponse alertData) async {
    if (_isShowing) return;
    _isShowing = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => NearbyReportsAlertModal(alertData: alertData),
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  State<NearbyReportsAlertModal> createState() => _NearbyReportsAlertModalState();
}

class _NearbyReportsAlertModalState extends State<NearbyReportsAlertModal> {
  late final PageController _cardPageController;
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _cardPageController = PageController();
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final reports = widget.alertData.reports;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Title & "X" Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.error,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n?.nearbyReportsAlertTitle(widget.alertData.count) ??
                          'Gần bạn có ${widget.alertData.count} phản ánh',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    tooltip: l10n?.closeButton ?? 'Đóng',
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(36, 36),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Slider Report Cards
              if (reports.isEmpty)
                const SizedBox.shrink()
              else ...[
                SizedBox(
                  height: 310,
                  child: PageView.builder(
                    controller: _cardPageController,
                    itemCount: reports.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentCardIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return _ReportCardItem(
                        report: report,
                        onViewDetail: () {
                          Navigator.of(context).pop();
                          final path = RouterPath.reportDetail.replaceAll(':id', report.id);
                          GoRouter.of(context).push(path);
                        },
                      );
                    },
                  ),
                ),
                if (reports.length > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous Button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
                        tooltip: l10n?.actionPrevious ?? 'Trước',
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          foregroundColor: _currentCardIndex > 0
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.25),
                          backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(32, 32),
                        ),
                        onPressed: _currentCardIndex > 0
                            ? () {
                                _cardPageController.previousPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Numbered indicator: "1/20"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          '${_currentCardIndex + 1}/${reports.length}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Next Button
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                        tooltip: l10n?.actionNext ?? 'Tiếp theo',
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          foregroundColor: _currentCardIndex < reports.length - 1
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.25),
                          backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(32, 32),
                        ),
                        onPressed: _currentCardIndex < reports.length - 1
                            ? () {
                                _cardPageController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 20),

              // Bottom Button "Đã hiểu"
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n?.actionUnderstood ?? 'Đã hiểu',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCardItem extends StatefulWidget {
  final NearbyReportItemModel report;
  final VoidCallback onViewDetail;

  const _ReportCardItem({
    required this.report,
    required this.onViewDetail,
  });

  @override
  State<_ReportCardItem> createState() => _ReportCardItemState();
}

class _ReportCardItemState extends State<_ReportCardItem> {
  late final PageController _imagePageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final images = widget.report.allImages;
    final distance = widget.report.distanceInMeters?.round() ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Slider
          SizedBox(
            height: 150,
            child: images.isEmpty
                ? Container(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 32,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n?.noImages ?? 'Không có hình ảnh',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _imagePageController,
                        itemCount: images.length,
                        onPageChanged: (idx) {
                          setState(() {
                            _currentImageIndex = idx;
                          });
                        },
                        itemBuilder: (context, idx) {
                          return Image.network(
                            images[idx],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1}/${images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),

          // Card Body: Distance badge, Title & View details button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Distance badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.near_me_rounded,
                        size: 13,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n?.nearbyDistanceInMeters(distance) ?? 'Cách bạn ${distance}m',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Report Title
                Text(
                  widget.report.title.isNotEmpty ? widget.report.title : 'Phản ánh sự cố',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                    onPressed: widget.onViewDetail,
                    icon: Text(
                      l10n?.actionViewDetail ?? 'Xem chi tiết',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    label: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
