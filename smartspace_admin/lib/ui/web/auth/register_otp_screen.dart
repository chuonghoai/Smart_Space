import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/ui/mobile/auth/register/register_controller.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'components/web_auth_layout.dart';

class WebRegisterOtpScreen extends StatefulWidget {
  const WebRegisterOtpScreen({super.key});

  @override
  State<WebRegisterOtpScreen> createState() => _WebRegisterOtpScreenState();
}

class _WebRegisterOtpScreenState extends State<WebRegisterOtpScreen> {
  late final RegisterController _controller;
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = registerController;
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return WebAuthLayout(
      showBackButton: true,
      onBack: () {
        if (!_controller.isLoading) {
          context.pop();
        }
      },
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.registerTitle,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.otpTitle,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.otpSentTo}: ${_controller.email}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 48),

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
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: l10n.enterOtp),
                onChanged: (value) => _controller.clearError(),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_controller.isLoading) {
                    _controller.verifyOtp(
                      context: context,
                      otpInput: _otpController.text,
                    );
                  }
                },
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _controller.isLoading
                    ? null
                    : () {
                        _controller.verifyOtp(
                          context: context,
                          otpInput: _otpController.text,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: _controller.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.verify,
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
    );
  }
}
