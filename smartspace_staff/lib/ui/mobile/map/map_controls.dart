import 'package:flutter/material.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

/// Map control buttons — my location, show all tasks, severity filter, refresh.
/// Lọc theo trạng thái nằm ở hàng chip phía trên bản đồ.
class MapControls extends StatelessWidget {
  final bool showDangerous;
  final bool showNormal;
  final VoidCallback onMyLocationPressed;
  final VoidCallback onShowAllTasksPressed;
  final VoidCallback onRefreshPressed;
  final void Function({bool? showDangerous, bool? showNormal}) onFilterChanged;

  const MapControls({
    super.key,
    required this.showDangerous,
    required this.showNormal,
    required this.onMyLocationPressed,
    required this.onShowAllTasksPressed,
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

          // Căn camera để thấy mọi việc được giao
          _ControlButton(
            icon: Icons.zoom_out_map_rounded,
            tooltip: l10n.mapShowAllTasks,
            onPressed: onShowAllTasksPressed,
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

          // Filter Normal (không nguy hiểm)
          _ControlButton(
            icon: Icons.place_outlined,
            tooltip: l10n.mapNormalReports,
            onPressed: () => onFilterChanged(showNormal: !showNormal),
            isActive: showNormal,
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
            // 13 + 22 + 13 = 48dp: vùng chạm tối thiểu
            padding: const EdgeInsets.all(13),
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
