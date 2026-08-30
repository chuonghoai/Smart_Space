import 'package:flutter/material.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/settings/change_password_controller.dart';

class MobileChangePasswordScreen extends StatefulWidget {
  const MobileChangePasswordScreen({super.key});

  @override
  State<MobileChangePasswordScreen> createState() =>
      _MobileChangePasswordScreenState();
}

class _MobileChangePasswordScreenState
    extends State<MobileChangePasswordScreen> {
  late final ChangePasswordController _controller;
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ChangePasswordController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePasswordTitle)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error message
                      if (_controller.error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _controller.error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),

                      // Field 1: Current password
                      _buildPasswordField(
                        theme: theme,
                        l10n: l10n,
                        label: l10n.currentPassword,
                        controller: _currentPasswordCtrl,
                        obscure: _controller.obscureCurrent,
                        onToggle: _controller.toggleObscureCurrent,
                      ),
                      const SizedBox(height: 20),

                      // Field 2: New password
                      _buildPasswordField(
                        theme: theme,
                        l10n: l10n,
                        label: l10n.newPassword,
                        controller: _newPasswordCtrl,
                        obscure: _controller.obscureNew,
                        onToggle: _controller.toggleObscureNew,
                      ),
                      const SizedBox(height: 20),

                      // Field 3: Confirm new password
                      _buildPasswordField(
                        theme: theme,
                        l10n: l10n,
                        label: l10n.confirmNewPassword,
                        controller: _confirmPasswordCtrl,
                        obscure: _controller.obscureConfirm,
                        onToggle: _controller.toggleObscureConfirm,
                      ),
                      const SizedBox(height: 24),

                      // Password requirements
                      _buildPasswordRequirements(theme, l10n),
                    ],
                  ),
                ),
              ),

              // Fixed bottom button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _controller.isLoading
                          ? null
                          : () => _controller.changePassword(
                              context: context,
                              currentPassword: _currentPasswordCtrl.text,
                              newPassword: _newPasswordCtrl.text,
                              confirmPassword: _confirmPasswordCtrl.text,
                            ),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _controller.isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              l10n.confirm,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required ThemeData theme,
    required AppLocalizations l10n,
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: l10n.enterInfo,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements(ThemeData theme, AppLocalizations l10n) {
    final requirements = [
      l10n.passwordReqLength,
      l10n.passwordReqMixed,
      l10n.passwordReqSpecial,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: requirements.map((req) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check, size: 16, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  req,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
