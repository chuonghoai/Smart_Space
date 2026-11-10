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
}
