import 'package:flutter/material.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

/// Map control buttons — settings, location, filters, refresh
class MapControls extends StatelessWidget {
  final bool showDangerous;
  final bool showNormal;
  final bool isDensityActive;
  final VoidCallback? onSettingsPressed;
  final VoidCallback onMyLocationPressed;
  final VoidCallback onRefreshPressed;
  final void Function({bool? showDangerous, bool? showNormal}) onFilterChanged;

  const MapControls({
    super.key,
    required this.showDangerous,
    required this.showNormal,
    this.isDensityActive = false,
    this.onSettingsPressed,
    required this.onMyLocationPressed,
    required this.onFilterChanged,
    required this.onRefreshPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      right: 12,
      child: Column(
        children: [
          // Map Settings / Density Toggle Sheet
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

          // Filter Dangerous
          MapControlButton(
            icon: Icons.warning_amber_rounded,
            tooltip: l10n.dangerousReports,
            onPressed: () => onFilterChanged(showDangerous: !showDangerous),
            isActive: showDangerous,
            activeColor: colorScheme.error,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),

          // Filter Normal
          MapControlButton(
            icon: Icons.place_outlined,
            tooltip: l10n.mapNormalReports,
            onPressed: () => onFilterChanged(showNormal: !showNormal),
            isActive: showNormal,
            activeColor: colorScheme.primary,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),

          // Refresh
          MapControlButton(
            icon: Icons.refresh,
            tooltip: l10n.refresh,
            onPressed: onRefreshPressed,
            colorScheme: colorScheme,
          ),
        ],
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
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? (activeColor ?? colorScheme.primary).withValues(alpha: 0.15)
            : colorScheme.surface,
        elevation: 4,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: 22,
              color: isActive
                  ? (activeColor ?? colorScheme.primary)
                  : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
