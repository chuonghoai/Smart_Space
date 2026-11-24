import 'package:flutter/material.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

import 'staff_location_map_mobile.dart'
    if (dart.library.html) 'staff_location_map_web.dart'
    as platform_picker;

Future<({double lat, double lng})?> showStaffLocationPickerDialog(
  BuildContext context, {
  double? initialLat,
  double? initialLng,
}) {
  return showDialog<({double lat, double lng})>(
    context: context,
    builder: (_) => _StaffLocationPickerDialog(
      initialLat: initialLat ?? 10.8231,
      initialLng: initialLng ?? 106.6297,
    ),
  );
}

class _StaffLocationPickerDialog extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const _StaffLocationPickerDialog({
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<_StaffLocationPickerDialog> createState() =>
      _StaffLocationPickerDialogState();
}

class _StaffLocationPickerDialogState
    extends State<_StaffLocationPickerDialog> {
  late double _lat = widget.initialLat;
  late double _lng = widget.initialLng;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final screenSize = MediaQuery.sizeOf(context);
    final width = screenSize.width < 680 ? screenSize.width - 32 : 640.0;
    final mapHeight = screenSize.height < 640 ? 280.0 : 380.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.staffLocationPickerTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.staffLocationPickerHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: mapHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: platform_picker.buildStaffLocationMap(
                    context: context,
                    initialLat: _lat,
                    initialLng: _lng,
                    onPicked: (lat, lng) {
                      setState(() {
                        _lat = lat;
                        _lng = lng;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Text(
                  '${l10n.staffBaseLatitudeLabel}: ${_lat.toStringAsFixed(6)}   ·   ${l10n.staffBaseLongitudeLabel}: ${_lng.toStringAsFixed(6)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, (lat: _lat, lng: _lng)),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.staffLocationConfirm),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
