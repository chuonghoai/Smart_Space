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

  @override
  String get retry => 'Retry';

  @override
  String get noLinkedReportsAvailable => 'No linked reports available';

  @override
  String get errorLoadingReports => 'Failed to load reports';

  @override
  String get callStatusConnecting => 'Connecting';

  @override
  String get callStatusRinging => 'Ringing';

  @override
  String get callStatusIncoming => 'Incoming voice call';

  @override
  String get callStatusAccepted => 'Setting up audio...';

  @override
  String get callStatusEnded => 'Call ended';

  @override
  String get callStatusRejected => 'Call ended';

  @override
  String get callStatusCancelled => 'Call cancelled';

  @override
  String get callStatusMissed => 'Missed call';

  @override
  String get callStatusFailed => 'Unable to connect';

  @override
  String get callMute => 'Mute';

  @override
  String get callUnmute => 'Unmute';

  @override
  String get callSpeaker => 'Speaker';

  @override
  String get callEarpiece => 'Earpiece';

  @override
  String get callBluetooth => 'Bluetooth';

  @override
  String get callWiredHeadset => 'Headset';

  @override
  String get callAudioOutput => 'Audio output';

  @override
  String get callEnd => 'End';

  @override
  String get callAccept => 'Answer';

  @override
  String get callReject => 'Decline';

  @override
  String get callMicPermissionDenied =>
      'Microphone permission is required for voice calls';

  @override
  String get callPermissionDenied =>
      'You do not have permission to call this user';

  @override
  String get callAnonymousUser => 'Anonymous User';

  @override
  String get callFreeVoiceDesc => 'Free internet voice call';

  @override
  String get callCellularUnavailable => 'Phone number unavailable';

  @override
  String get callFreeUnavailable =>
      'Voice call unavailable for this conversation';

  @override
  String get callOptionsTitle => 'Call options';

  @override
  String get callCellularTitle => 'Regular call';

  @override
  String get callCellularDesc => 'Open default phone dialer';

  @override
  String get callFreeTitle => 'Free call';

  @override
  String get callClose => 'Close';

  @override
  String get rehandlingLabel => 'Re-handling';

  @override
  String get statusProcessingLabel => 'Processing';

  @override
  String get statusProcessedLabel => 'Processed';

  @override
  String get statusPendingLabel => 'Pending';

  @override
  String attachSelectedCount(int count) {
    return 'Attach ($count)';
  }

  @override
  String get selectRehandlingReportsTitle => 'Select re-handling reports';

  @override
  String get noRehandlingReportsAvailable =>
      'No re-handling reports currently in progress';
}
