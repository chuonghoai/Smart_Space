import 'package:flutter/material.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mở vị trí report trên Google Maps (app ngoài) để staff tìm đường tới hiện trường.
/// Không mở được → SnackBar báo lỗi.
Future<void> openInGoogleMaps(BuildContext context, double lat, double lng) async {
  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  final messenger = ScaffoldMessenger.maybeOf(context);
  final errorText = AppLocalizations.of(context)!.cannotOpenGoogleMapsError;

  final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!opened) {
    messenger?.showSnackBar(SnackBar(content: Text(errorText)));
  }
}
