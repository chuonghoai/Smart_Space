// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'shared_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class SharedLocalizationsVi extends SharedLocalizations {
  SharedLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String distanceFromYou(String value, String unit) {
    return 'Cách bạn $value $unit';
  }

  @override
  String get sendMessageFailed => 'Gửi tin nhắn thất bại, bấm để thử lại';

  @override
  String get sendingMessage => 'Đang gửi tin nhắn...';

  @override
  String get markAsRead => 'Đánh dấu đã đọc';

  @override
  String get selectReportToAttach => 'Chọn phản ánh để gửi';

  @override
  String get typingText => 'đang nhập...';

  @override
  String get pressAndHoldToRecord => 'Nhấn giữ để ghi âm';

  @override
  String get slideLeftToCancel => 'Trượt sang để hủy';

  @override
  String get releaseToCancel => 'Thả để hủy';

  @override
  String get micPermissionRequired =>
      'Vui lòng cấp quyền truy cập microphone để ghi âm';

  @override
  String get attachedReport => 'Phản ánh đính kèm';

  @override
  String get tapToViewReport => 'Nhấn để xem chi tiết';

  @override
  String get cannotPlayVideo => 'Không thể phát video';

  @override
  String get downloadMedia => 'Tải xuống';

  @override
  String get downloadingMedia => 'Đang tải xuống...';

  @override
  String get downloadSuccess => 'Đã lưu vào thiết bị thành công';

  @override
  String get downloadFailed => 'Tải xuống thất bại';

  @override
  String get holdToRecordPrompt => 'Nhấn giữ để bắt đầu thu âm';

  @override
  String get recordingAudio => 'Đang thu âm...';

  @override
  String get discardAudio => 'Hủy';

  @override
  String get sendAudio => 'Gửi';

  @override
  String get mediaOptions => 'Tùy chọn phương tiện';

  @override
  String get seekBack10s => 'Lùi 10 giây';

  @override
  String get seekForward10s => 'Tua tới 10 giây';

  @override
  String get playbackPreview => 'Nghe lại âm thanh';
}
