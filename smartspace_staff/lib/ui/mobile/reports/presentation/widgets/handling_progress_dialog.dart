import 'package:flutter/material.dart';
import 'package:smartspace_staff/features/reports/services/handle_report_background_service.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

class HandlingProgressDialog extends StatefulWidget {
  final String reportId;

  const HandlingProgressDialog({super.key, required this.reportId});

  static Future<void> show(BuildContext context, String reportId) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => HandlingProgressDialog(reportId: reportId),
    );
  }

  @override
  State<HandlingProgressDialog> createState() => _HandlingProgressDialogState();
}

class _HandlingProgressDialogState extends State<HandlingProgressDialog> {
  bool _autoDismissTriggered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: handleReportBackgroundService,
      builder: (context, _) {
        final task = handleReportBackgroundService.getTask(widget.reportId);
        final isCompleted = task?.status == HandleTaskStatus.success;
        final isError = task?.status == HandleTaskStatus.error;

        if (isCompleted && !_autoDismissTriggered) {
          _autoDismissTriggered = true;
          final navigator = Navigator.of(context);
          Future.delayed(const Duration(milliseconds: 1400), () {
            if (mounted && navigator.canPop()) {
              navigator.pop();
            }
          });
        }

        final double? progressValue = (task != null && task.totalSteps > 0)
            ? (task.currentStep / task.totalSteps)
            : null;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: theme.colorScheme.surface,
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Icon Header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? theme.colorScheme.primaryContainer
                      : isError
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : isError
                          ? Icons.error_outline_rounded
                          : Icons.cloud_upload_outlined,
                  size: 36,
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : isError
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                isCompleted
                    ? l10n.reportProcessedSuccess
                    : isError
                        ? l10n.errorTitle
                        : l10n.submittingReportBackgroundTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),

              // Description / Message
              Text(
                isCompleted
                    ? l10n.handlingCompletedSuccess
                    : isError
                        ? (task?.errorMessage ?? l10n.errorOccurred(''))
                        : l10n.submittingReportBackground,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Progress Bar & Step info (only when in progress)
              if (!isCompleted && !isError) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.handlingProgressTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${task?.currentStep ?? 0}/${task?.totalSteps ?? 1}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(l10n.gotIt),
              ),
            ),
          ],
        );
      },
    );
  }
}
