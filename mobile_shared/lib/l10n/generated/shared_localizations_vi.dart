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

  @override
  String get retry => 'Thử lại';

  @override
  String get noLinkedReportsAvailable => 'Không có phản ánh liên kết khả dụng';

  @override
  String get errorLoadingReports => 'Lỗi tải danh sách phản ánh';

  @override
  String get callStatusConnecting => 'Đang kết nối';

  @override
  String get callStatusRinging => 'Đang đổ chuông';

  @override
  String get callStatusIncoming => 'Cuộc gọi thoại đến';

  @override
  String get callStatusAccepted => 'Đang thiết lập âm thanh...';

  @override
  String get callStatusEnded => 'Đã kết thúc cuộc gọi';

  @override
  String get callStatusRejected => 'Đã kết thúc cuộc gọi';

  @override
  String get callStatusCancelled => 'Đã hủy cuộc gọi';

  @override
  String get callStatusMissed => 'Cuộc gọi nhỡ';

  @override
  String get callStatusFailed => 'Không thể kết nối';

  @override
  String get callMute => 'Tắt mic';

  @override
  String get callUnmute => 'Bật mic';

  @override
  String get callSpeaker => 'Loa ngoài';

  @override
  String get callEarpiece => 'Loa trong';

  @override
  String get callBluetooth => 'Bluetooth';

  @override
  String get callWiredHeadset => 'Tai nghe';

  @override
  String get callAudioOutput => 'Đầu ra âm thanh';

  @override
  String get callEnd => 'Kết thúc';

  @override
  String get callAccept => 'Trả lời';

  @override
  String get callReject => 'Từ chối';

  @override
  String get callMicPermissionDenied =>
      'Cần quyền microphone để thực hiện cuộc gọi thoại';

  @override
  String get callPermissionDenied =>
      'Bạn không có quyền gọi điện cho người dùng này';

  @override
  String get callAnonymousUser => 'Người dùng ẩn danh';

  @override
  String get callFreeVoiceDesc => 'Gọi thoại miễn phí qua Internet';

  @override
  String get callCellularUnavailable => 'Không có số điện thoại khả dụng';

  @override
  String get callFreeUnavailable => 'Chưa đủ điều kiện gọi miễn phí';

  @override
  String get callOptionsTitle => 'Tùy chọn cuộc gọi';

  @override
  String get callCellularTitle => 'Gọi thường';

  @override
  String get callCellularDesc => 'Mở ứng dụng gọi điện mặc định';

  @override
  String get callFreeTitle => 'Gọi miễn phí';

  @override
  String get callClose => 'Đóng';

  @override
  String get rehandlingLabel => 'Xử lý lại';

  @override
  String get statusProcessingLabel => 'Đang xử lý';

  @override
  String get statusProcessedLabel => 'Đã xử lý';

  @override
  String get statusPendingLabel => 'Chờ xử lý';

  @override
  String attachSelectedCount(int count) {
    return 'Đính kèm ($count)';
  }

  @override
  String get selectRehandlingReportsTitle => 'Chọn phản ánh xử lý lại';

  @override
  String get noRehandlingReportsAvailable =>
      'Không có phản ánh xử lý lại nào đang xử lý';
}
