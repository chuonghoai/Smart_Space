import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

/// Control buttons cho bản đồ Admin — cài đặt/mật độ, vị trí của tôi, làm mới.
class MapControls extends StatelessWidget {
  final bool isDensityActive;
  final VoidCallback? onSettingsPressed;
  final VoidCallback onMyLocationPressed;
  final VoidCallback onRefreshPressed;

  const MapControls({
    super.key,
    this.isDensityActive = false,
    this.onSettingsPressed,
    required this.onMyLocationPressed,
    required this.onRefreshPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      top: 16,
      right: 16,
      child: PointerInterceptor(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Settings / Density Toggle
            if (onSettingsPressed != null) ...[
              MapControlButton(
                icon: Icons.layers_outlined,
                tooltip: l10n.mapSettings,
                onPressed: onSettingsPressed!,
                isActive: isDensityActive,
                activeColor: colorScheme.primary,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
            ],

            // My Location
            MapControlButton(
              icon: Icons.my_location,
              tooltip: l10n.myLocation,
              onPressed: onMyLocationPressed,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),

            // Refresh
            MapControlButton(
              icon: Icons.refresh,
              tooltip: l10n.mapRefresh,
              onPressed: onRefreshPressed,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
}

class MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? activeColor;
  final ColorScheme colorScheme;

  const MapControlButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.activeColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? effectiveActiveColor
            : colorScheme.surface.withValues(alpha: 0.92),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isActive
                ? effectiveActiveColor
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 20,
              color: isActive
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

