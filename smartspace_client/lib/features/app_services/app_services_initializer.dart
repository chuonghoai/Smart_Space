import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_client/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';

/// Global widget that initializes app-level services once and keeps them alive
/// for the entire lifecycle of the app, regardless of which screen is visible.
///
/// Responsibilities:
///  - Sets up the WebSocket notification listener (STOMP), retrying whenever
///    connectionStateProvider becomes "ready" (both WS + FCM connected).
///  - Listens to FCM tap events (foreground, background, terminated) and navigates.
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

    // IMPORTANT: Listen to connectionStateProvider, NOT just webSocketService.
    // webSocketService.subscribe() internally requires connectionStateProvider.isReady()
    // (i.e., both WebSocket AND FCM token must be registered). So we only call
    // setupWebSocketListener() once the whole connection stack is fully ready.
    _connectionStateListener = () {
      if (connectionStateProvider.isReady()) {
        debugPrint('[AppServices] connectionStateProvider → READY, setting up WebSocket listener...');
        _setupWebSocket();
      } else {
        // Connection dropped — reset the subscription guard so we can re-subscribe on reconnect.
        ref.read(notificationProvider.notifier).resetWebSocketSubscription();
      }
    };
    connectionStateProvider.addListener(_connectionStateListener!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Handle terminated-state notification tap
      FirebaseService.checkInitialMessage();

      // Try immediate setup in case already ready (e.g. user already logged in)
      if (connectionStateProvider.isReady()) {
        debugPrint('[AppServices] Already connected on first frame, setting up WebSocket listener...');
        _setupWebSocket();
      }
    });
  }

  /// Navigate based on FCM data payload
  void _handleFcmTap(Map<String, dynamic> data) {
    debugPrint('[AppServices] FCM tap received — data=$data');
    final reportId = data['reportId'] as String?;
    if (reportId != null && reportId.isNotEmpty) {
      final path = RouterPath.reportDetail.replaceAll(':id', reportId);
      debugPrint('[AppServices] FCM tap → navigating to $path');
      final ctx = sharedNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        GoRouter.of(ctx).push(path);
      } else {
        debugPrint('[AppServices] FCM tap — navigatorKey context is null, cannot navigate');
      }
    } else {
      debugPrint('[AppServices] FCM tap — no reportId in data, ignoring');
    }
  }

  /// Setup WebSocket STOMP listener for real-time in-app notifications.
  /// Safe to call multiple times — the provider guards against duplicate subscriptions.
  void _setupWebSocket() {
    // Resolve l10n from navigator context
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

    debugPrint('[AppServices] Calling setupWebSocketListener...');
    ref.read(notificationProvider.notifier).setupWebSocketListener(
      actionLabel: l10n.actionView,
      onAction: (reportId) {
        final navigatorCtx = sharedNavigatorKey.currentContext;
        if (navigatorCtx != null && navigatorCtx.mounted) {
          final path = RouterPath.reportDetail.replaceAll(':id', reportId);
          GoRouter.of(navigatorCtx).push(path);
        }
      },
    );
  }

  @override
  void dispose() {
    _fcmTapSub?.cancel();
    if (_connectionStateListener != null) {
      connectionStateProvider.removeListener(_connectionStateListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
