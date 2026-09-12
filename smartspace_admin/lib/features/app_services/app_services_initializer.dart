import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/features/app_services/ws_services_registry.dart';
import 'package:smartspace_admin/features/notifications/models/notification_action.dart';
import 'package:smartspace_admin/features/notifications/services/notification_router.dart';

/// Global widget that initializes app-level services once and keeps them alive
/// for the entire lifecycle of the app, regardless of which screen is visible.
class AppServicesInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const AppServicesInitializer({super.key, required this.child});

  @override
  ConsumerState<AppServicesInitializer> createState() =>
      _AppServicesInitializerState();
}

class _AppServicesInitializerState
    extends ConsumerState<AppServicesInitializer> {
  StreamSubscription<Map<String, dynamic>>? _fcmTapSub;
  VoidCallback? _connectionStateListener;

  @override
  void initState() {
    super.initState();

    // Setup FCM tap → navigate listener
    _fcmTapSub = FirebaseService.onNotificationTapped.listen(_handleFcmTap);

    _connectionStateListener = () {
      if (connectionStateProvider.isReady()) {
        debugPrint('[AppServices] connectionStateProvider → READY, setting up WebSocket listeners...');
        _setupWebSockets();
      } else {
        WsServicesRegistry.resetAll();
      }
    };
    connectionStateProvider.addListener(_connectionStateListener!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseService.checkInitialMessage();

      if (connectionStateProvider.isReady()) {
        debugPrint('[AppServices] Already connected on first frame, setting up WebSocket listeners...');
        _setupWebSockets();
      }
    });
  }

  /// Navigate based on FCM data payload
  void _handleFcmTap(Map<String, dynamic> data) {
    debugPrint('[AppServices] FCM tap received — data=$data');
    final action = NotificationAction.fromJson(data);
    if (action.type.isNotEmpty) {
      NotificationRouter.handleAction(action);
    } else {
      debugPrint('[AppServices] FCM tap — no action type in data, ignoring');
    }
  }

  void _setupWebSockets() {
    WsServicesRegistry.setupAll();
  }

  @override
  void dispose() {
    _fcmTapSub?.cancel();
    if (_connectionStateListener != null) {
      connectionStateProvider.removeListener(_connectionStateListener!);
    }
    WsServicesRegistry.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
