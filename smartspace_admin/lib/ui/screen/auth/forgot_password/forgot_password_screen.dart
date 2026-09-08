import 'package:flutter/material.dart';
import 'package:smartspace_admin/ui/screen/auth/forgot_password/forgot_password_controller.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import '../../../shared/login_setting/login_setting.dart';

class AdminForgotPasswordScreen extends StatefulWidget {
  const AdminForgotPasswordScreen({super.key});

  @override
  State<AdminForgotPasswordScreen> createState() => _AdminForgotPasswordScreenState();
}

class _AdminForgotPasswordScreenState extends State<AdminForgotPasswordScreen> {
  late final ForgotPasswordController _controller;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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
      backgroundColor: colorScheme.surfaceContainerHighest,
      endDrawer: const LoginSetting(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          final formContent = SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? constraints.maxWidth * 0.1 : 24.0,
              vertical: 24.0,
            ),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isDesktop) ...[
                      Icon(Icons.lock_reset, size: 64, color: colorScheme.primary),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      '${l10n.forgotPasswordTitle} Admin',
                      style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.forgotPasswordSubtitle,
                      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (_controller.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                        child: Text(_controller.error!, style: TextStyle(color: colorScheme.onErrorContainer), textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(l10n.email, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                              if (!_controller.isSendingOtp && !_controller.isResettingPassword) {
                                _controller.sendOtp(context: context, email: _emailController.text);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: l10n.email,
                              border: const OutlineInputBorder(),
                            ),
                            enabled: !_controller.isSendingOtp && !_controller.isResettingPassword,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _controller.isSendingOtp || _controller.isResettingPassword
                              ? null
                              : () {
                                  _controller.sendOtp(context: context, email: _emailController.text);
                                },
                          child: _controller.isSendingOtp
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(l10n.send),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.otp, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _otpController,
                      focusNode: _otpFocusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _newPasswordFocusNode.requestFocus(),
                      decoration: InputDecoration(
                        hintText: l10n.enterOtp,
                        border: const OutlineInputBorder(),
                      ),
                      enabled: _controller.otpSent && !_controller.isResettingPassword,
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.newPassword, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newPasswordController,
                      focusNode: _newPasswordFocusNode,
                      obscureText: _obscureNewPassword,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                      decoration: InputDecoration(
                        hintText: l10n.enterPassword,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      enabled: _controller.otpSent && !_controller.isResettingPassword,
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.confirmPassword, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_controller.isResettingPassword && _controller.otpSent) {
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
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      enabled: _controller.otpSent && !_controller.isResettingPassword,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: (_controller.isResettingPassword || !_controller.otpSent)
                          ? null
                          : () {
                              _controller.resetPassword(
                                context: context,
                                email: _emailController.text,
                                otp: _otpController.text,
                                newPassword: _newPasswordController.text,
                                confirmPassword: _confirmPasswordController.text,
                              );
                            },
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _controller.isResettingPassword
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(l10n.resetPassword, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
            ),
          );

          if (isDesktop) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    color: colorScheme.primaryContainer,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_reset, size: 120, color: colorScheme.primary),
                          const SizedBox(height: 24),
                          Text(
                            '${l10n.smartSpaceAppName} Admin',
                            style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Center(
                    child: formContent,
                  ),
                ),
              ],
            );
          }

          return SafeArea(
            child: Center(
              child: formContent,
            ),
          );
        },
      ),
    );
  }
}
