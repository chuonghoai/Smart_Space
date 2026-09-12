import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/screen/auth/login/login_controller.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import '../../../shared/login_setting/login_setting.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  late final LoginController _controller;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
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

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      endDrawer: const LoginSetting(),
      body: Stack(
        children: [
          LayoutBuilder(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.admin_panel_settings, size: 64, color: colorScheme.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '${l10n.smartSpaceAppName} Admin',
                              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                    Text(l10n.welcomeBack, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.left),
                    const SizedBox(height: 8),
                    Text(l10n.signInToContinue, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.left),
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
                    TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      dragStartBehavior: DragStartBehavior.down,
                      mouseCursor: SystemMouseCursors.text,
                      onTap: () {
                        if (_emailController.selection.baseOffset != _emailController.selection.extentOffset) {
                          _emailController.selection = TextSelection.collapsed(
                            offset: _emailController.selection.extentOffset,
                          );
                        }
                      },
                      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                      decoration: InputDecoration(
                        hintText: l10n.email,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.password, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      dragStartBehavior: DragStartBehavior.down,
                      mouseCursor: SystemMouseCursors.text,
                      onTap: () {
                        if (_passwordController.selection.baseOffset != _passwordController.selection.extentOffset) {
                          _passwordController.selection = TextSelection.collapsed(
                            offset: _passwordController.selection.extentOffset,
                          );
                        }
                      },
                      onSubmitted: (_) {
                        if (!_controller.isLoading) {
                          _controller.login(context: context, email: _emailController.text, password: _passwordController.text, rememberMe: _rememberMe);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: l10n.password,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: _controller.isLoading ? null : (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            Text(l10n.rememberMe),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.push(RouterPath.forgotPassword),
                          child: Text(l10n.forgotPassword),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _controller.isLoading ? null : () {
                        _controller.login(context: context, email: _emailController.text, password: _passwordController.text, rememberMe: _rememberMe);
                      },
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _controller.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(l10n.login, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                          Icon(Icons.admin_panel_settings, size: 120, color: colorScheme.primary),
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
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
