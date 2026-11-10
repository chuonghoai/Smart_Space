// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'shared_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SharedLocalizationsEn extends SharedLocalizations {
  SharedLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String distanceFromYou(String value, String unit) {
    return '$value $unit away';
  }

  @override
  String get sendMessageFailed => 'Failed to send message, tap to retry';

  @override
  String get sendingMessage => 'Sending message...';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get selectReportToAttach => 'Select report to attach';

  @override
  String get typingText => 'is typing...';

  @override
  String get pressAndHoldToRecord => 'Hold to record';

  @override
  String get slideLeftToCancel => 'Slide to cancel';

  @override
  String get releaseToCancel => 'Release to cancel';

  @override
  String get micPermissionRequired =>
      'Please grant microphone permission to record audio';

  @override
  String get attachedReport => 'Attached Report';

  @override
  String get tapToViewReport => 'Tap to view details';

  @override
  String get cannotPlayVideo => 'Cannot play video';

  @override
  String get downloadMedia => 'Download';

  @override
  String get downloadingMedia => 'Downloading...';

  @override
  String get downloadSuccess => 'Saved to device successfully';

  @override
  String get downloadFailed => 'Failed to download';

  @override
  String get holdToRecordPrompt => 'Press and hold to start recording';

  @override
  String get recordingAudio => 'Recording...';

  @override
  String get discardAudio => 'Discard';

  @override
  String get sendAudio => 'Send';

  @override
  String get mediaOptions => 'Media options';

  @override
  String get seekBack10s => 'Back 10 seconds';

  @override
  String get seekForward10s => 'Forward 10 seconds';

  @override
  String get playbackPreview => 'Audio playback preview';
}
