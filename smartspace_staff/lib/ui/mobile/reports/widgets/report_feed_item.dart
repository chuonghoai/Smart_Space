import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

class ReportFeedItem extends StatelessWidget {
  final ReportModel report;
  final Position? userPosition;
  final VoidCallback onTap;

  const ReportFeedItem({
    super.key,
    required this.report,
    required this.onTap,
    this.userPosition,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    String statusText = l10n.reportStatusUnknown;
    Color statusColor = Colors.grey;

    switch (report.status) {
      case ReportStatus.pending:
        statusText = l10n.reportStatusPending;
        statusColor = Colors.orange;
        break;
      case ReportStatus.processing:
        statusText = l10n.reportStatusProcessing;
        statusColor = Colors.purple;
        break;
      case ReportStatus.processed:
        statusText = l10n.reportStatusProcessed;
        statusColor = Colors.green;
        break;
      case ReportStatus.rejected:
        statusText = l10n.reportStatusRejected;
        statusColor = Colors.red;
        break;
      default:
        statusText = l10n.reportStatusUnknown;
        statusColor = Colors.grey;
        break;
    }

    String severityText = '';
    Color severityColor = Colors.grey;
    switch (report.severity) {
      case ReportSeverity.low:
        severityText = l10n.severityLow;
        severityColor = Colors.green;
        break;
      case ReportSeverity.medium:
        severityText = l10n.severityMedium;
        severityColor = Colors.orange;
        break;
      case ReportSeverity.high:
        severityText = l10n.severityHigh;
        severityColor = Colors.deepOrange;
        break;
      case ReportSeverity.critical:
        severityText = l10n.severityCritical;
        severityColor = Colors.red;
        break;
      default:
        severityText = '';
        break;
    }

    final displayDate = report.assignedAt ?? report.createdAt;
    final dateStr = '${displayDate.day.toString().padLeft(2, '0')}/${displayDate.month.toString().padLeft(2, '0')}/${displayDate.year} ${displayDate.hour.toString().padLeft(2, '0')}:${displayDate.minute.toString().padLeft(2, '0')}';

    final isNew = report.assignedAt != null && DateTime.now().difference(report.assignedAt!) < const Duration(hours: 24);

    String? distanceStr;
    if (userPosition != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        userPosition!.latitude,
        userPosition!.longitude,
        report.latitude,
        report.longitude,
      );
      if (distanceInMeters < 1000) {
        distanceStr = '${distanceInMeters.toStringAsFixed(0)} m';
      } else {
        distanceStr = '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
      }
    }

    final String displayName = report.isAnonymous 
        ? l10n.anonymousUser 
        : (report.userName?.isNotEmpty == true ? report.userName! : l10n.anonymousUser);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (report.imageUrl.isNotEmpty)
              Image.network(
                report.imageUrl,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(height: 180, color: theme.colorScheme.surfaceContainerHighest, child: const Icon(Icons.image, size: 48)),
              )
            else
              Container(
                height: 120,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image, size: 48),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: report.isAnonymous || report.userAvatarUrl == null || report.userAvatarUrl!.isEmpty
                            ? null
                            : NetworkImage(report.userAvatarUrl!),
                        child: report.isAnonymous || report.userAvatarUrl == null || report.userAvatarUrl!.isEmpty
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          report.title,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isNew)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.newLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (severityText.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: severityColor.withOpacity(0.5)),
                              ),
                              child: Text(
                                severityText,
                                style: TextStyle(
                                  color: severityColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (distanceStr != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            l10n.distanceAway(distanceStr),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
