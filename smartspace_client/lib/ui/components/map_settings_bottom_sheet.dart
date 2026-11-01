import 'package:flutter/material.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

class MapSettingsBottomSheet extends StatelessWidget {
  final bool isDensityEnabled;
  final ValueChanged<bool> onDensityToggle;

  const MapSettingsBottomSheet({
    super.key,
    required this.isDensityEnabled,
    required this.onDensityToggle,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isDensityEnabled,
    required ValueChanged<bool> onDensityToggle,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => MapSettingsBottomSheet(
        isDensityEnabled: isDensityEnabled,
        onDensityToggle: onDensityToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      elevation: 10,
      child: Padding(
        padding: EdgeInsets.only(
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  l10n.mapSettings,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Toggle Density
          SwitchListTile.adaptive(
            value: isDensityEnabled,
            onChanged: (val) {
              onDensityToggle(val);
            },
            title: Text(
              l10n.mapDensityToggle,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              l10n.mapDensityDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.layers_rounded, color: colorScheme.primary, size: 22),
            ),
            activeThumbColor: colorScheme.primary,
          ),
        ],
      ),
      ),
    );
  }
}

