import 'package:flutter/material.dart';
import 'package:mobile_shared/features/auth/models/DeviceSessionModel.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/settings/manage_devices_controller.dart';

class MobileManageDevicesScreen extends StatefulWidget {
  const MobileManageDevicesScreen({super.key});

  @override
  State<MobileManageDevicesScreen> createState() =>
      _MobileManageDevicesScreenState();
}

class _MobileManageDevicesScreenState extends State<MobileManageDevicesScreen> {
  late final ManageDevicesController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ManageDevicesController();
    _ctrl.loadSessions();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _successColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? const Color(0xFF2E7D32)
          : const Color(0xFF66BB6A);

  String _formatLastActive(BuildContext context, int epochMs) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(epochMs),
    );
    if (diff.inMinutes < 5) return l10n.activeNow;
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageDevices)),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          if (_ctrl.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_ctrl.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _ctrl.error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _ctrl.loadSessions,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }
          return _buildBody(theme, l10n);
        },
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section header
        Text(
          l10n.loggedInDevices,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Current device card
        if (_ctrl.currentDevice != null)
          _buildCurrentDeviceCard(theme, l10n, _ctrl.currentDevice!),

        const SizedBox(height: 16),
        if (_ctrl.otherDevices.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: 8),
          // Other devices
          ..._ctrl.otherDevices.map(
            (session) => _buildOtherDeviceTile(theme, l10n, session),
          ),
          const SizedBox(height: 16),
          // Logout all button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutAllDialog(context, l10n, theme),
              icon: Icon(Icons.logout, color: theme.colorScheme.error),
              label: Text(
                l10n.logoutAllOtherDevices,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: theme.colorScheme.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
        if (_ctrl.otherDevices.isEmpty) ...[
          const SizedBox(height: 24),
          Center(
            child: Text(
              l10n.noOtherDevices,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentDeviceCard(
    ThemeData theme,
    AppLocalizations l10n,
    DeviceSessionModel device,
  ) {
    final successColor = _successColor(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              device.deviceIcon,
              size: 36,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          device.deviceName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: successColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.thisDevice,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: successColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (device.ipAddress != null)
                    Text(
                      device.ipAddress!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.activeNow,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherDeviceTile(
    ThemeData theme,
    AppLocalizations l10n,
    DeviceSessionModel device,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        child: ListTile(
          leading: Icon(
            device.deviceIcon,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(device.deviceName, style: theme.textTheme.bodyLarge),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (device.ipAddress != null)
                Text(
                  device.ipAddress!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              Text(
                _formatLastActive(context, device.lastActiveAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          trailing: OutlinedButton(
            onPressed: () =>
                _showLogoutDeviceDialog(context, l10n, theme, device),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.error),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              l10n.logoutDevice,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDeviceDialog(
    BuildContext ctx,
    AppLocalizations l10n,
    ThemeData theme,
    DeviceSessionModel device,
  ) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(l10n.logoutDeviceConfirmTitle),
        content: Text(l10n.logoutDeviceConfirmMessage(device.deviceName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _ctrl.revokeSession(context, device.sessionId);
            },
            child: Text(
              l10n.logout,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllDialog(
    BuildContext ctx,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(l10n.logoutAllConfirmTitle),
        content: Text(l10n.logoutAllConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _ctrl.revokeAllOtherSessions(context);
            },
            child: Text(
              l10n.logout,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
