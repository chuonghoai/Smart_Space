import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/screen/auth/forgot_password/forgot_password_controller.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import '../../../shared/login_setting/login_setting.dart';
import '../widgets/auth_branding_panel.dart';

class AdminForgotPasswordScreen extends StatefulWidget {
  const AdminForgotPasswordScreen({super.key});

  @override
  State<AdminForgotPasswordScreen> createState() =>
      _AdminForgotPasswordScreenState();
}

class _AdminForgotPasswordScreenState extends State<AdminForgotPasswordScreen> {
  late final ForgotPasswordController _controller;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _controller = ForgotPasswordController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _otpFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouterPath.login);
    }
  }

  void _submitSendOtp() {
    if (!_controller.isSendingOtp && !_controller.isResettingPassword) {
      _controller.sendOtp(context: context, email: _emailController.text);
    }
  }

  void _submitResetPassword() {
    if (!_controller.isResettingPassword && _controller.otpSent) {
      _controller.resetPassword(
        context: context,
        email: _emailController.text,
        otp: _otpController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            endDrawer: const LoginSetting(),
            body: _buildDesktopLayout(context, l10n, colorScheme, textTheme),
          );
        }

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerHighest,
          endDrawer: const LoginSetting(),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleBack,
            ),
            actions: [
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                  );
                },
              ),
            ],
          ),
          body: _buildMobileLayout(context, l10n, colorScheme, textTheme),
        );
      },
    );
  }

  /// Preserved mobile layout for phones and compact displays.
  Widget _buildMobileLayout(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 24.0,
          ),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_reset, size: 64, color: colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    '${l10n.forgotPasswordTitle} Admin',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.forgotPasswordSubtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_controller.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _controller.error!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    l10n.email,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          dragStartBehavior: DragStartBehavior.down,
                          mouseCursor: SystemMouseCursors.text,
                          onTap: () {
                            if (_emailController.selection.baseOffset !=
                                _emailController.selection.extentOffset) {
                              _emailController.selection =
                                  TextSelection.collapsed(
                                    offset:
                                        _emailController.selection.extentOffset,
                                  );
                            }
                          },
                          onSubmitted: (_) => _submitSendOtp(),
                          decoration: InputDecoration(
                            hintText: l10n.email,
                            border: const OutlineInputBorder(),
                          ),
                          enabled:
                              !_controller.isSendingOtp &&
                              !_controller.isResettingPassword,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed:
                            _controller.isSendingOtp ||
                                    _controller.isResettingPassword
                                ? null
                                : _submitSendOtp,
                        child: _controller.isSendingOtp
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.send),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.otp,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    dragStartBehavior: DragStartBehavior.down,
                    mouseCursor: SystemMouseCursors.text,
                    onTap: () {
                      if (_otpController.selection.baseOffset !=
                          _otpController.selection.extentOffset) {
                        _otpController.selection = TextSelection.collapsed(
                          offset: _otpController.selection.extentOffset,
                        );
                      }
                    },
                    onSubmitted: (_) => _newPasswordFocusNode.requestFocus(),
                    decoration: InputDecoration(
                      hintText: l10n.enterOtp,
                      border: const OutlineInputBorder(),
                    ),
                    enabled:
                        _controller.otpSent &&
                        !_controller.isResettingPassword,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.newPassword,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPasswordController,
                    focusNode: _newPasswordFocusNode,
                    obscureText: _obscureNewPassword,
                    textInputAction: TextInputAction.next,
                    dragStartBehavior: DragStartBehavior.down,
                    mouseCursor: SystemMouseCursors.text,
                    onTap: () {
                      if (_newPasswordController.selection.baseOffset !=
                          _newPasswordController.selection.extentOffset) {
                        _newPasswordController.selection =
                            TextSelection.collapsed(
                              offset:
                                  _newPasswordController.selection.extentOffset,
                            );
                      }
                    },
                    onSubmitted: (_) =>
                        _confirmPasswordFocusNode.requestFocus(),
                    decoration: InputDecoration(
                      hintText: l10n.enterPassword,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                    ),
                    enabled:
                        _controller.otpSent &&
                        !_controller.isResettingPassword,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.confirmPassword,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    dragStartBehavior: DragStartBehavior.down,
                    mouseCursor: SystemMouseCursors.text,
                    onTap: () {
                      if (_confirmPasswordController.selection.baseOffset !=
                          _confirmPasswordController.selection.extentOffset) {
                        _confirmPasswordController.selection =
                            TextSelection.collapsed(
                              offset: _confirmPasswordController
                                  .selection
                                  .extentOffset,
                            );
                      }
                    },
                    onSubmitted: (_) => _submitResetPassword(),
                    decoration: InputDecoration(
                      hintText: l10n.confirmPassword,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    enabled:
                        _controller.otpSent &&
                        !_controller.isResettingPassword,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: (_controller.isResettingPassword ||
                            !_controller.otpSent)
                        ? null
                        : _submitResetPassword,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _controller.isResettingPassword
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.resetPassword,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Modern responsive desktop layout with security recovery guidance and constrained form width.
  Widget _buildDesktopLayout(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        // Left Column: Account Security & Guidance Panel
        Expanded(
          flex: 5,
          child: AuthBrandingPanel(
            badgeText: l10n.forgotPasswordHeroTitle,
            badgeIcon: Icons.lock_reset_rounded,
            title: '${l10n.smartSpaceAppName} Admin',
            subtitle: l10n.forgotPasswordHeroSubtitle,
            highlights: [
              AuthHighlightItem(
                icon: Icons.mark_email_read_outlined,
                title: l10n.stepEmailVerification,
                description: l10n.forgotPasswordSubtitle,
              ),
              AuthHighlightItem(
                icon: Icons.password_rounded,
                title: l10n.stepPasswordReset,
                description: l10n.passwordResetSuccessfully,
              ),
              AuthHighlightItem(
                icon: Icons.support_agent_rounded,
                title: l10n.help,
                description: l10n.forgotPasswordHelpNote,
              ),
            ],
            footerNotice: l10n.systemSecureNotice,
          ),
        ),

        // Right Column: Form Panel
        Expanded(
          flex: 6,
          child: Container(
            color: colorScheme.surface,
            child: Stack(
              children: [
                // Top Navigation Row
                Positioned(
                  top: 24,
                  left: 32,
                  right: 32,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back to login button
                      TextButton.icon(
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(
                          l10n.backToLogin,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                        onPressed: _handleBack,
                      ),

                      // Settings button
                      Builder(
                        builder: (context) {
                          return OutlinedButton.icon(
                            icon: Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            label: Text(
                              l10n.settings,
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            onPressed: () {
                              Scaffold.of(context).openEndDrawer();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Form Container
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 64.0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.lock_reset_rounded,
                                      size: 24,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.forgotPasswordTitle,
                                          style: textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: colorScheme.onSurface,
                                                letterSpacing: -0.4,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l10n.forgotPasswordSubtitle,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color:
                                                colorScheme.onSurfaceVariant,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Error alert banner
                              if (_controller.error != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: colorScheme.error.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        size: 20,
                                        color: colorScheme.error,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _controller.error!,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onErrorContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Success banner
                              if (_controller.successMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _controller.successMessage!,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Email Label & Field with Send Button
                              Text(
                                l10n.email,
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                      dragStartBehavior: DragStartBehavior.down,
                                      mouseCursor: SystemMouseCursors.text,
                                      onTap: () {
                                        if (_emailController
                                                .selection.baseOffset !=
                                            _emailController
                                                .selection.extentOffset) {
                                          _emailController.selection =
                                              TextSelection.collapsed(
                                                offset: _emailController
                                                    .selection.extentOffset,
                                              );
                                        }
                                      },
                                      onSubmitted: (_) => _submitSendOtp(),
                                      decoration: InputDecoration(
                                        hintText: l10n.email,
                                        prefixIcon: Icon(
                                          Icons.alternate_email_rounded,
                                          size: 20,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                      ),
                                      enabled:
                                          !_controller.isSendingOtp &&
                                          !_controller.isResettingPassword,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    height: 48,
                                    child: FilledButton(
                                      onPressed:
                                          _controller.isSendingOtp ||
                                                  _controller.isResettingPassword
                                              ? null
                                              : _submitSendOtp,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                      ),
                                      child: _controller.isSendingOtp
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: colorScheme.onPrimary,
                                              ),
                                            )
                                          : Text(
                                              l10n.send,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // OTP Label & Field
                              Text(
                                l10n.otp,
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _controller.otpSent
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _otpController,
                                focusNode: _otpFocusNode,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                dragStartBehavior: DragStartBehavior.down,
                                mouseCursor: SystemMouseCursors.text,
                                onTap: () {
                                  if (_otpController.selection.baseOffset !=
                                      _otpController.selection.extentOffset) {
                                    _otpController.selection =
                                        TextSelection.collapsed(
                                          offset: _otpController
                                              .selection
                                              .extentOffset,
                                        );
                                  }
                                },
                                onSubmitted: (_) =>
                                    _newPasswordFocusNode.requestFocus(),
                                decoration: InputDecoration(
                                  hintText: l10n.enterOtp,
                                  prefixIcon: Icon(
                                    Icons.pin_outlined,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                enabled:
                                    _controller.otpSent &&
                                    !_controller.isResettingPassword,
                              ),
                              const SizedBox(height: 20),

                              // New Password Label & Field
                              Text(
                                l10n.newPassword,
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _controller.otpSent
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _newPasswordController,
                                focusNode: _newPasswordFocusNode,
                                obscureText: _obscureNewPassword,
                                textInputAction: TextInputAction.next,
                                dragStartBehavior: DragStartBehavior.down,
                                mouseCursor: SystemMouseCursors.text,
                                onTap: () {
                                  if (_newPasswordController
                                          .selection.baseOffset !=
                                      _newPasswordController
                                          .selection.extentOffset) {
                                    _newPasswordController.selection =
                                        TextSelection.collapsed(
                                          offset: _newPasswordController
                                              .selection
                                              .extentOffset,
                                        );
                                  }
                                },
                                onSubmitted: (_) =>
                                    _confirmPasswordFocusNode.requestFocus(),
                                decoration: InputDecoration(
                                  hintText: l10n.enterPassword,
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureNewPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureNewPassword =
                                            !_obscureNewPassword;
                                      });
                                    },
                                  ),
                                ),
                                enabled:
                                    _controller.otpSent &&
                                    !_controller.isResettingPassword,
                              ),
                              const SizedBox(height: 20),

                              // Confirm Password Label & Field
                              Text(
                                l10n.confirmPassword,
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _controller.otpSent
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocusNode,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                dragStartBehavior: DragStartBehavior.down,
                                mouseCursor: SystemMouseCursors.text,
                                onTap: () {
                                  if (_confirmPasswordController
                                          .selection.baseOffset !=
                                      _confirmPasswordController
                                          .selection.extentOffset) {
                                    _confirmPasswordController.selection =
                                        TextSelection.collapsed(
                                          offset: _confirmPasswordController
                                              .selection
                                              .extentOffset,
                                        );
                                  }
                                },
                                onSubmitted: (_) => _submitResetPassword(),
                                decoration: InputDecoration(
                                  hintText: l10n.confirmPassword,
                                  prefixIcon: Icon(
                                    Icons.lock_reset_rounded,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                enabled:
                                    _controller.otpSent &&
                                    !_controller.isResettingPassword,
                              ),
                              const SizedBox(height: 32),

                              // Reset Password Action Button
                              FilledButton(
                                onPressed: (_controller.isResettingPassword ||
                                        !_controller.otpSent)
                                    ? null
                                    : _submitResetPassword,
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: _controller.isResettingPassword
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: colorScheme.onPrimary,
                                        ),
                                      )
                                    : Text(
                                        l10n.resetPassword,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
