import 'dart:async';
import 'package:flutter/material.dart';

enum ToastType {
  error,
  warning,
  success,
  info
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Shared navigator key — client must assign this to GoRouter's navigatorKey.
/// Used as fallback context for overlays (Toast, etc.) when scaffoldMessengerKey has no context.
final GlobalKey<NavigatorState> sharedNavigatorKey = GlobalKey<NavigatorState>();

class Toast {
  static void show(ToastType type, String message) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case ToastType.error:
        backgroundColor = Colors.red.shade700;
        icon = Icons.error_outline;
        break;
      case ToastType.warning:
        backgroundColor = Colors.orange.shade800;
        icon = Icons.warning_amber_rounded;
        break;
      case ToastType.success:
        backgroundColor = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      case ToastType.info:
        backgroundColor = Colors.blue.shade700;
        icon = Icons.info_outline;
        break;
    }

    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showTopNotification({
    required BuildContext? context,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    OverlayState? overlayState;
    if (context != null) {
      try {
        overlayState = Overlay.maybeOf(context);
      } catch (_) {}
    }
    
    // Fallback to the navigator's overlay if context is null or has no overlay
    overlayState ??= sharedNavigatorKey.currentState?.overlay;

    if (overlayState == null) {
      debugPrint('[Toast] No Overlay widget found to show top notification.');
      return;
    }

    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          overlayEntry?.remove();
        },
      ),
    );
    
    overlayState.insert(overlayEntry);
  }

  static void showToast(BuildContext? context, String message) {
    OverlayState? overlayState;
    if (context != null) {
      try {
        overlayState = Overlay.maybeOf(context);
      } catch (_) {}
    }
    overlayState ??= sharedNavigatorKey.currentState?.overlay;

    if (overlayState == null) {
      show(ToastType.success, message);
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastOverlayCapsule(
        message: message,
        onDismiss: () {
          entry.remove();
        },
      ),
    );
    overlayState.insert(entry);
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    _timer = Timer(const Duration(seconds: 4), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _timer?.cancel();
    _controller.reverse().then((value) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _dismiss();
              widget.onAction?.call();
            },
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta! < -2) {
                _dismiss();
              }
            },
            child: SlideTransition(
              position: _offsetAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.actionLabel != null && widget.onAction != null)
                      TextButton(
                        onPressed: () {
                          _dismiss();
                          widget.onAction!();
                        },
                        child: Text(widget.actionLabel!),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _ToastOverlayCapsule extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ToastOverlayCapsule({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlayCapsule> createState() => _ToastOverlayCapsuleState();
}

class _ToastOverlayCapsuleState extends State<_ToastOverlayCapsule>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 2000), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _timer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 32,
      right: 32,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xE6212121),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF81C784),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
