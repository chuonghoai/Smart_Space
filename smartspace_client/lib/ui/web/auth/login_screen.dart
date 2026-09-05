import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_web/web_only.dart' as web_gsi;
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/mobile/auth/login/login_controller.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'components/web_auth_layout.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  late final LoginController _controller;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _googleInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    await _controller.initializeGoogleSignIn();
    if (mounted) {
      _controller.listenForWebGoogleSignIn(context);
      setState(() {
        _googleInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return WebAuthLayout(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.welcomeBack,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.signInToContinue,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
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
              Text(
                l10n.email,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  if (!_controller.isLoading) {
                    _controller.login(
                      context: context,
                      email: _emailController.text,
                      password: _passwordController.text,
                      rememberMe: _rememberMe,
                    );
                  }
                },
                decoration: InputDecoration(hintText: l10n.email),
              ),
              const SizedBox(height: 24),
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
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_controller.isLoading) {
                    _controller.login(
                      context: context,
                      email: _emailController.text,
                      password: _passwordController.text,
                      rememberMe: _rememberMe,
                    );
                  }
                },
                decoration: InputDecoration(
                  hintText: l10n.password,
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
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: _controller.isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Text(l10n.rememberMe),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      context.push(RouterPath.forgotPassword);
                    },
                    child: Text(
                      l10n.forgotPassword,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _controller.isLoading
                    ? null
                    : () {
                        _controller.login(
                          context: context,
                          email: _emailController.text,
                          password: _passwordController.text,
                          rememberMe: _rememberMe,
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
                        l10n.login,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.orContinueWith,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 40),

              // Google Sign-In Button (Web) — rendered by Google SDK
              if (_googleInitialized)
                SizedBox(
                  height: 44,
                  child: web_gsi.renderButton(
                    configuration: web_gsi.GSIButtonConfiguration(
                      type: web_gsi.GSIButtonType.standard,
                      theme: web_gsi.GSIButtonTheme.outline,
                      size: web_gsi.GSIButtonSize.large,
                      shape: web_gsi.GSIButtonShape.rectangular,
                      text: web_gsi.GSIButtonText.signinWith,
                      minimumWidth: 400,
                    ),
                  ),
                )
              else
                const SizedBox(
                  height: 44,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.areYouNewUser, style: textTheme.bodyMedium),
                  TextButton(
                    onPressed: () {
                      context.push(RouterPath.registerEmail);
                    },
                    child: Text(
                      l10n.signUp,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
