import 'package:flutter/material.dart';
import 'package:mobile_shared/core/connection/connection_manager.dart';
import 'package:mobile_shared/core/connection/connection_state_provider.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: connectionStateProvider,
      builder: (context, child) {
        final state = connectionStateProvider.state;

        String tooltipText;
        Widget indicator;

        switch (state) {
          case GlobalConnectionState.connected:
            tooltipText = l10n?.connectionStable ?? 'Stable connection';
            indicator = const Icon(Icons.wifi, color: Colors.green, size: 20);
            break;
          case GlobalConnectionState.connecting:
            tooltipText = l10n?.connectionConnecting ?? 'Connecting realtime services...';
            indicator = const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
            break;
          case GlobalConnectionState.error:
          case GlobalConnectionState.disconnected:
            tooltipText = l10n?.connectionDisconnected ?? 'Realtime connection lost. Click to reconnect.';
            indicator = IconButton(
              icon: const Icon(Icons.wifi_off, color: Colors.red, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: tooltipText,
              onPressed: () {
                connectionManager.resumeConnections();
              },
            );
            return indicator;
        }

        return Tooltip(
          message: tooltipText,
          child: indicator,
        );
      },
    );
  }
}
