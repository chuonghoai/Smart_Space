import 'package:flutter/material.dart';

/// Reusable confirmation dialog.
///
/// Usage:
/// ```dart
/// final confirmed = await ConfirmDialog.show(
///   context: context,
///   title: 'Are you sure?',
///   message: 'This action cannot be undone.',
///   okLabel: 'Yes',
///   cancelLabel: 'No',
/// );
/// if (confirmed == true) { ... }
/// ```
class ConfirmDialog {
  ConfirmDialog._();

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required String okLabel,
    required String cancelLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(okLabel),
          ),
        ],
      ),
    );
  }
}
