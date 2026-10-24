import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_staff/features/reports/services/report_service.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

enum HandleTaskStatus { idle, inProgress, success, error }

class HandleReportTask {
  final String reportId;
  int currentStep;
  int totalSteps;
  String statusMessage;
  HandleTaskStatus status;
  String? errorMessage;

  HandleReportTask({
    required this.reportId,
    this.currentStep = 0,
    this.totalSteps = 0,
    this.statusMessage = '',
    this.status = HandleTaskStatus.idle,
    this.errorMessage,
  });
}

class HandleReportBackgroundService extends ChangeNotifier {
  FlutterLocalNotificationsPlugin get _plugin =>
      FirebaseService.localNotificationsPlugin;

  final Map<String, HandleReportTask> _tasks = {};

  bool isHandling(String reportId) {
    final task = _tasks[reportId];
    return task != null && task.status == HandleTaskStatus.inProgress;
  }

  HandleReportTask? getTask(String reportId) => _tasks[reportId];

  Future<void> _showNotification({
    required int id,
    required int progress,
    required int maxProgress,
    required String title,
    required String body,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'handle_report_channel_id',
      'Tiến độ xử lý phản ánh',
      channelDescription:
          'Hiển thị tiến độ tải lên minh chứng và gửi kết quả xử lý phản ánh',
      importance: Importance.max,
      priority: Priority.high,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      onlyAlertOnce: true,
      enableVibration: false,
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> startHandlingReport({
    required String reportId,
    required String note,
    required List<Uint8List> images,
    required List<String> fileNames,
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    final notifId = reportId.hashCode.abs() % 100000;
    final int totalSteps = images.length + 1;

    final l10n = lookupAppLocalizations(ui.PlatformDispatcher.instance.locale);

    final task = HandleReportTask(
      reportId: reportId,
      currentStep: 0,
      totalSteps: totalSteps,
      statusMessage: l10n.submittingReportBackground,
      status: HandleTaskStatus.inProgress,
    );
    _tasks[reportId] = task;
    notifyListeners();

    try {
      List<String> uploadedUrls = [];

      for (int i = 0; i < images.length; i++) {
        task.currentStep = i + 1;
        task.statusMessage =
            l10n.uploadingEvidenceProgress(task.currentStep, totalSteps);
        notifyListeners();

        await _showNotification(
          id: notifId,
          progress: task.currentStep,
          maxProgress: totalSteps,
          title: l10n.submittingReportBackgroundTitle,
          body: l10n.uploadingEvidenceProgress(task.currentStep, totalSteps),
        );

        final fileName = i < fileNames.length
            ? fileNames[i]
            : 'evidence_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final String url =
            await mediaUploadUtil.uploadMedia(images[i], fileName);
        if (url.isNotEmpty) {
          uploadedUrls.add(url);
        }
      }

      // Step N: Call API completeReport
      task.currentStep = totalSteps;
      task.statusMessage = l10n.almostDoneFinalizing(totalSteps, totalSteps);
      notifyListeners();

      await _showNotification(
        id: notifId,
        progress: totalSteps,
        maxProgress: totalSteps,
        title: l10n.submittingReportBackgroundTitle,
        body: l10n.almostDoneFinalizing(totalSteps, totalSteps),
      );

      final response = await reportService.completeReport(
        reportId,
        note: note,
        imageUrls: uploadedUrls,
      );

      if (response.success) {
        task.status = HandleTaskStatus.success;
        task.statusMessage = l10n.handlingCompletedSuccess;
        notifyListeners();

        // Cancel notification on completion per user requirement
        await _plugin.cancel(id: notifId);
        onSuccess?.call();
      } else {
        task.status = HandleTaskStatus.error;
        task.errorMessage = response.message;
        notifyListeners();

        await _plugin.cancel(id: notifId);
        onError?.call(response.message);
      }
    } catch (e) {
      task.status = HandleTaskStatus.error;
      task.errorMessage = e.toString();
      notifyListeners();

      await _plugin.cancel(id: notifId);
      onError?.call(e.toString());
    }
  }
}

final handleReportBackgroundService = HandleReportBackgroundService();
