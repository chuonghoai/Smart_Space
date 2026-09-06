import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_client/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_client/features/notifications/services/notification_ws_service.dart';
import 'package:smartspace_client/features/notifications/services/notification_router.dart';
import 'package:smartspace_client/features/notifications/models/notification_action.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

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
  NotificationWsService? _wsService;

  @override
  void initState() {
    super.initState();

    // Setup FCM tap → navigate listener
    _fcmTapSub = FirebaseService.onNotificationTapped.listen(_handleFcmTap);

    _connectionStateListener = () {
      if (connectionStateProvider.isReady()) {
        debugPrint('[AppServices] connectionStateProvider → READY, setting up WebSocket listener...');
        _setupWebSocket();
      } else {
        _wsService?.reset();
      }
    };
    connectionStateProvider.addListener(_connectionStateListener!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseService.checkInitialMessage();

      if (connectionStateProvider.isReady()) {
        debugPrint('[AppServices] Already connected on first frame, setting up WebSocket listener...');
        _setupWebSocket();
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

  void _setupWebSocket() {
    final ctx = sharedNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      debugPrint('[AppServices] _setupWebSocket — navigatorKey context is null, skipping.');
      return;
    }

    final l10n = AppLocalizations.of(ctx);
    if (l10n == null) {
      debugPrint('[AppServices] _setupWebSocket — l10n not available yet.');
      return;
    }

    if (_wsService == null) {
      _wsService = NotificationWsService(
        actionLabel: l10n.actionView,
        onNotificationReceived: () {
          ref.read(notificationProvider.notifier).onNotificationReceived();
        },
      );
    }

    debugPrint('[AppServices] Calling wsService.setup()...');
    _wsService!.setup();
  }

  @override
  void dispose() {
    _fcmTapSub?.cancel();
    if (_connectionStateListener != null) {
      connectionStateProvider.removeListener(_connectionStateListener!);
    }
    _wsService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

