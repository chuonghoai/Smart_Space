import 'package:flutter/material.dart';
import 'package:smartspace_admin/ui/mobile/auth/forgot_password/forgot_password_controller.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import '../../../shared/login_setting/login_setting.dart';

class MobileForgotPasswordScreen extends StatefulWidget {
  const MobileForgotPasswordScreen({super.key});

  @override
  State<MobileForgotPasswordScreen> createState() =>
      _MobileForgotPasswordScreenState();
}

class _MobileForgotPasswordScreenState
    extends State<MobileForgotPasswordScreen> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      endDrawer: const LoginSetting(),
      body: SafeArea(
        bottom: false,
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
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
                    const SizedBox(height: 24),

                    // Logo Placeholder
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_reset,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Text(
                            l10n.forgotPasswordTitle,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Subtitle
                    const SizedBox(height: 16),
                    Text(
                      l10n.forgotPasswordSubtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error message
                    if (_controller.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _controller.error!,
                          style: TextStyle(color: colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email input
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
                            onSubmitted: (_) {
                              if (!_controller.isSendingOtp &&
                                  !_controller.isResettingPassword) {
                                _controller.sendOtp(
                                  context: context,
                                  email: _emailController.text,
                                );
                              }
                            },
                            decoration: InputDecoration(hintText: l10n.email),
                            enabled:
                                !_controller.isSendingOtp &&
                                !_controller.isResettingPassword,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed:
                              _controller.isSendingOtp ||
                                  _controller.isResettingPassword
                              ? null
                              : () {
                                  _controller.sendOtp(
                                    context: context,
                                    email: _emailController.text,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          child: _controller.isSendingOtp
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.send),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // OTP input
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
                      onSubmitted: (_) => _newPasswordFocusNode.requestFocus(),
                      decoration: InputDecoration(hintText: l10n.enterOtp),
                      enabled:
                          _controller.otpSent &&
                          !_controller.isResettingPassword,
                    ),
                    const SizedBox(height: 20),

                    // Password input
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
                      onSubmitted: (_) =>
                          _confirmPasswordFocusNode.requestFocus(),
                      decoration: InputDecoration(
                        hintText: l10n.enterPassword,
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

                    // Confirm Password input
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
                      onSubmitted: (_) {
                        if (!_controller.isResettingPassword &&
                            _controller.otpSent) {
                          _controller.resetPassword(
                            context: context,
                            email: _emailController.text,
                            otp: _otpController.text,
                            newPassword: _newPasswordController.text,
                            confirmPassword: _confirmPasswordController.text,
                          );
                        }
                      },
                      decoration: InputDecoration(
                        hintText: l10n.confirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
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

                    // Reset Password button
                    ElevatedButton(
                      onPressed:
                          (_controller.isResettingPassword ||
                              !_controller.otpSent)
                          ? null
                          : () {
                              _controller.resetPassword(
                                context: context,
                                email: _emailController.text,
                                otp: _otpController.text,
                                newPassword: _newPasswordController.text,
                                confirmPassword:
                                    _confirmPasswordController.text,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _controller.isResettingPassword
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              l10n.resetPassword,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
