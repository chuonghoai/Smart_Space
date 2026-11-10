import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'shared_localizations_en.dart';
import 'shared_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SharedLocalizations
/// returned by `SharedLocalizations.of(context)`.
///
/// Applications need to include `SharedLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/shared_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SharedLocalizations.localizationsDelegates,
///   supportedLocales: SharedLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the SharedLocalizations.supportedLocales
/// property.
abstract class SharedLocalizations {
  SharedLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SharedLocalizations? of(BuildContext context) {
    return Localizations.of<SharedLocalizations>(context, SharedLocalizations);
  }

  static const LocalizationsDelegate<SharedLocalizations> delegate =
      _SharedLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @distanceFromYou.
  ///
  /// In vi, this message translates to:
  /// **'Cách bạn {value} {unit}'**
  String distanceFromYou(String value, String unit);

  /// No description provided for @sendMessageFailed.
  ///
  /// In vi, this message translates to:
  /// **'Gửi tin nhắn thất bại, bấm để thử lại'**
  String get sendMessageFailed;

  /// No description provided for @sendingMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi tin nhắn...'**
  String get sendingMessage;

  /// No description provided for @markAsRead.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đã đọc'**
  String get markAsRead;

  /// No description provided for @selectReportToAttach.
  ///
  /// In vi, this message translates to:
  /// **'Chọn phản ánh để gửi'**
  String get selectReportToAttach;

  /// No description provided for @typingText.
  ///
  /// In vi, this message translates to:
  /// **'đang nhập...'**
  String get typingText;

  /// No description provided for @pressAndHoldToRecord.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn giữ để ghi âm'**
  String get pressAndHoldToRecord;

  /// No description provided for @slideLeftToCancel.
  ///
  /// In vi, this message translates to:
  /// **'Trượt sang để hủy'**
  String get slideLeftToCancel;

  /// No description provided for @releaseToCancel.
  ///
  /// In vi, this message translates to:
  /// **'Thả để hủy'**
  String get releaseToCancel;

  /// No description provided for @micPermissionRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng cấp quyền truy cập microphone để ghi âm'**
  String get micPermissionRequired;

  /// No description provided for @attachedReport.
  ///
  /// In vi, this message translates to:
  /// **'Phản ánh đính kèm'**
  String get attachedReport;

  /// No description provided for @tapToViewReport.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn để xem chi tiết'**
  String get tapToViewReport;

  /// No description provided for @cannotPlayVideo.
  ///
  /// In vi, this message translates to:
  /// **'Không thể phát video'**
  String get cannotPlayVideo;

  /// No description provided for @downloadMedia.
  ///
  /// In vi, this message translates to:
  /// **'Tải xuống'**
  String get downloadMedia;

  /// No description provided for @downloadingMedia.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải xuống...'**
  String get downloadingMedia;

  /// No description provided for @downloadSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu vào thiết bị thành công'**
  String get downloadSuccess;

  /// No description provided for @downloadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Tải xuống thất bại'**
  String get downloadFailed;

  /// No description provided for @holdToRecordPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn giữ để bắt đầu thu âm'**
  String get holdToRecordPrompt;

  /// No description provided for @recordingAudio.
  ///
  /// In vi, this message translates to:
  /// **'Đang thu âm...'**
  String get recordingAudio;

  /// No description provided for @discardAudio.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get discardAudio;

  /// No description provided for @sendAudio.
  ///
  /// In vi, this message translates to:
  /// **'Gửi'**
  String get sendAudio;

  /// No description provided for @mediaOptions.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn phương tiện'**
  String get mediaOptions;

  /// No description provided for @seekBack10s.
  ///
  /// In vi, this message translates to:
  /// **'Lùi 10 giây'**
  String get seekBack10s;

  /// No description provided for @seekForward10s.
  ///
  /// In vi, this message translates to:
  /// **'Tua tới 10 giây'**
  String get seekForward10s;

  /// No description provided for @playbackPreview.
  ///
  /// In vi, this message translates to:
  /// **'Nghe lại âm thanh'**
  String get playbackPreview;
}

class _SharedLocalizationsDelegate
    extends LocalizationsDelegate<SharedLocalizations> {
  const _SharedLocalizationsDelegate();

  @override
  Future<SharedLocalizations> load(Locale locale) {
    return SynchronousFuture<SharedLocalizations>(
      lookupSharedLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_SharedLocalizationsDelegate old) => false;
}

SharedLocalizations lookupSharedLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SharedLocalizationsEn();
    case 'vi':
      return SharedLocalizationsVi();
  }

  throw FlutterError(
    'SharedLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
