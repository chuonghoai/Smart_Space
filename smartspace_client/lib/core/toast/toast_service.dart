import 'package:flutter/material.dart';

enum ToastType {
  error,
  warning,
  success,
  info
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
}
