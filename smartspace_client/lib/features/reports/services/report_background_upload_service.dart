import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smartspace_client/features/reports/models/report_dto.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

class ReportBackgroundUploadService extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  int _totalSteps = 0;
  int _currentStep = 0;
  String _statusMessage = '';

  int get totalSteps => _totalSteps;
  int get currentStep => _currentStep;
  String get statusMessage => _statusMessage;

  ReportModel? _lastUploadedReport;
  ReportModel? get lastUploadedReport => _lastUploadedReport;

  ReportBackgroundUploadService() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> _showNotification(int progress, int maxProgress, String title, String body, {bool showProgress = true}) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'upload_channel_id',
      'Upload Progress',
      channelDescription: 'Shows progress for report uploads',
      importance: Importance.max,
      priority: Priority.high,
      showProgress: showProgress,
      maxProgress: maxProgress,
      progress: progress,
      onlyAlertOnce: true,
      enableVibration: false,
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(),
    );
    await _flutterLocalNotificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> startUploadAndCreateReport(ReportDto dto, List<Uint8List> images, {Function(ReportModel)? onSuccess}) async {
    if (_isUploading) return;
    
    await _flutterLocalNotificationsPlugin.cancel(id: 0);
    
    final l10n = lookupAppLocalizations(ui.PlatformDispatcher.instance.locale);

    _isUploading = true;
    _totalSteps = images.length;
    _currentStep = 0;
    _statusMessage = l10n.uploadingImage;
    notifyListeners();

    try {
      List<String> uploadedUrls = [];
      
      for (int i = 0; i < images.length; i++) {
        _currentStep = i + 1;
        _statusMessage = l10n.uploadingImageProgress(_currentStep, images.length);
        notifyListeners();
        
        await _showNotification(_currentStep, _totalSteps, l10n.uploadingImage, l10n.imageProgress(_currentStep, images.length));
        
        String url = await mediaUploadUtil.uploadMedia(images[i], 'report_img_$i.jpg');
        if (url.isNotEmpty) {
          uploadedUrls.add(url);
        }
      }

      _currentStep = _totalSteps;
      _statusMessage = l10n.creatingReportSystem;
      notifyListeners();
      await _showNotification(_currentStep, _totalSteps, l10n.almostDone, l10n.creatingReportOnSystem);

      ReportDto updatedDto = dto.copyWith(imageUrls: uploadedUrls);
      final response = await reportService.createReport(updatedDto);

      if (response.success && response.data != null) {
        _lastUploadedReport = response.data;
        _statusMessage = l10n.createReportSuccess;
        await _showNotification(0, 0, l10n.success, l10n.reportRecorded, showProgress: false);
        if (onSuccess != null) {
          onSuccess(response.data!);
        }
        scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(l10n.createReportSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _statusMessage = l10n.errorString(response.message);
        await _showNotification(0, 0, l10n.errorPrefix, l10n.cannotCreateReportError(response.message), showProgress: false);
      }
    } catch (e) {
      _statusMessage = l10n.errorString(e.toString());
      await _showNotification(0, 0, l10n.errorPrefix, l10n.errorOccurredSendingReport(e.toString()), showProgress: false);
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}

final reportBackgroundUploadService = ReportBackgroundUploadService();
