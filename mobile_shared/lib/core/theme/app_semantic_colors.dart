import 'package:flutter/material.dart';

/// Semantic colors theo `app_architecture/design/design.md`.
/// Error dùng `ColorScheme.error`; extension này bổ sung Success / Warning / Info.
///
/// Dùng: `AppSemanticColors.of(context).success`
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color warning;
  final Color info;

  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.info,
  });

  static const light = AppSemanticColors(
    success: Color(0xFF2E7D32),
    warning: Color(0xFFF9A825),
    info: Color(0xFF1565C0),
  );

  static const dark = AppSemanticColors(
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFCA28),
    info: Color(0xFF42A5F5),
  );

  /// Fallback theo brightness khi theme chưa đăng ký extension.
  static AppSemanticColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  AppSemanticColors copyWith({Color? success, Color? warning, Color? info}) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
