import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_staff/ui/mobile/auth/register/register_controller.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'components/web_auth_layout.dart';

class WebRegisterPasswordScreen extends StatefulWidget {
  const WebRegisterPasswordScreen({super.key});

  @override
  State<WebRegisterPasswordScreen> createState() =>
      _WebRegisterPasswordScreenState();
}

class _WebRegisterPasswordScreenState extends State<WebRegisterPasswordScreen> {
  late final RegisterController _controller;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = registerController;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
                l10n.passwordTitle,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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

              // Password input
              Text(
                l10n.password,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  if (!_controller.isLoading) {
                    _controller.registerAccount(
                      context: context,
                      password: _passwordController.text,
                      confirmPassword: _confirmPasswordController.text,
                    );
                  }
                },
                decoration: InputDecoration(
                  hintText: l10n.enterPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                onChanged: (value) => _controller.clearError(),
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
                  if (!_controller.isLoading) {
                    _controller.registerAccount(
                      context: context,
                      password: _passwordController.text,
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
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                onChanged: (value) => _controller.clearError(),
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _controller.isLoading
                    ? null
                    : () {
                        _controller.registerAccount(
                          context: context,
                          password: _passwordController.text,
                          confirmPassword: _confirmPasswordController.text,
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
                        l10n.createAccount,
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
