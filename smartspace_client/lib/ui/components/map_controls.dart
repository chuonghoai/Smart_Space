import 'package:flutter/material.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

/// Map control buttons — filter, my location, refresh
class MapControls extends StatelessWidget {
  final bool showDangerous;
  final bool showRecent;
  final VoidCallback onMyLocationPressed;
  final VoidCallback onRefreshPressed;
  final void Function({bool? showDangerous, bool? showRecent}) onFilterChanged;

  const MapControls({
    super.key,
    required this.showDangerous,
    required this.showRecent,
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
          // My Location
          _ControlButton(
            icon: Icons.my_location,
            tooltip: l10n.myLocation,
            onPressed: onMyLocationPressed,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),

          // Filter Dangerous
          _ControlButton(
            icon: Icons.warning_amber_rounded,
            tooltip: l10n.dangerousReports,
            onPressed: () => onFilterChanged(showDangerous: !showDangerous),
            isActive: showDangerous,
            activeColor: colorScheme.error,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),

          // Filter Recent
          _ControlButton(
            icon: Icons.access_time_rounded,
            tooltip: l10n.recentReports,
            onPressed: () => onFilterChanged(showRecent: !showRecent),
            isActive: showRecent,
            activeColor: colorScheme.primary,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),

          // Refresh
          _ControlButton(
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

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? activeColor;
  final ColorScheme colorScheme;

  const _ControlButton({
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
