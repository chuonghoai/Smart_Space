import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/features/auth/services/auth_service.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_client/features/notifications/services/notification_router.dart';
import 'package:smartspace_client/features/notifications/models/notification_action.dart';
import 'package:smartspace_client/features/reports/providers/nearby_reports_alert_provider.dart';
import 'package:smartspace_client/routes/router_path.dart';

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
    extends ConsumerState<AppServicesInitializer> with WidgetsBindingObserver {
  StreamSubscription<Map<String, dynamic>>? _fcmTapSub;
  VoidCallback? _connectionStateListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Setup FCM tap → navigate listener
    _fcmTapSub = FirebaseService.onNotificationTapped.listen(_handleFcmTap);

    final callCtrl = ref.read(callControllerProvider.notifier);
    callCtrl.onCallScreenRequested = (callId) {
      final ctx = sharedNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      final router = GoRouter.of(ctx);
      final targetPath = RouterPath.voiceCallWithId(callId);
      if (router.routeInformationProvider.value.uri.path == targetPath) return;
      router.push(targetPath);
    };
    AuthService.onBeforeLogout = () async {
      if (mounted) {
        await callCtrl.cleanupOnLogout();
      }
    };

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
      FirebaseService.requestPermission();

      if (connectionStateProvider.isReady()) {
        debugPrint('[AppServices] Already connected on first frame, setting up WebSocket listeners...');
        _setupWebSockets();
      }
    });
  }

  /// Navigate based on FCM data payload
  void _handleFcmTap(Map<String, dynamic> data) {
    debugPrint('[AppServices] FCM tap received — data=$data');
    final type = data['type']?.toString() ?? '';
    if (type == 'WS_CALL_INCOMING') {
      ref
          .read(callControllerProvider.notifier)
          .openActiveCallFromNotice(data['callId']?.toString() ?? '');
      return;
    }
    final action = NotificationAction.fromJson(data);
    if (action.type.isNotEmpty) {
      NotificationRouter.handleAction(action);
    } else {
      debugPrint('[AppServices] FCM tap — no action type in data, ignoring');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(callControllerProvider.notifier).onAppLifecycleChanged(state);
  }

  void _setupWebSockets() {
    WsServicesRegistry.setupAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fcmTapSub?.cancel();
    if (_connectionStateListener != null) {
      connectionStateProvider.removeListener(_connectionStateListener!);
    }
    WsServicesRegistry.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep 15-minute nearby reports alert provider & global call controller alive
    ref.watch(nearbyReportsAlertProvider);
    ref.listen<CallState>(callControllerProvider, (_, _) {});
    return widget.child;
  }
}
