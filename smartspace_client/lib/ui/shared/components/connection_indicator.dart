import 'package:flutter/material.dart';
import 'package:smartspace_client/core/connection/connection_state_provider.dart';

class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: connectionStateProvider,
      builder: (context, child) {
        final state = connectionStateProvider.state;
        
        switch (state) {
          case GlobalConnectionState.connected:
            return const Icon(Icons.wifi, color: Colors.green, size: 20);
          case GlobalConnectionState.connecting:
            return const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          case GlobalConnectionState.error:
          case GlobalConnectionState.disconnected:
            return const Icon(Icons.wifi_off, color: Colors.red, size: 20);
        }
      },
    );
  }
}
