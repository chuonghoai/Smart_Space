import 'package:flutter/material.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// URL chỉ đường chính thức của Google Maps (Maps URLs API): mở thẳng tuyến đường từ vị trí
/// hiện tại tới [lat], [lng]. Không ép phương tiện → Google Maps dùng phương tiện người dùng chọn gần nhất.
Uri googleMapsDirectionsUri(double lat, double lng) => Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
    });

/// Mở Google Maps (app nếu đã cài, không thì trình duyệt) để dẫn đường staff tới hiện trường.
/// Không mở được → SnackBar báo lỗi.
Future<void> openGoogleMapsDirections(BuildContext context, double lat, double lng) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final errorText = AppLocalizations.of(context)!.cannotOpenGoogleMapsError;

  var opened = false;
  try {
    opened = await launchUrl(googleMapsDirectionsUri(lat, lng), mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('[GoogleMaps] Failed to open directions — $e');
  }
  if (!opened) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(errorText)));
  }
}
