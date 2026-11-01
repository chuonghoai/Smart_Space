import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/screen/auth/login/login_controller.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import '../../../shared/login_setting/login_setting.dart';
import '../widgets/auth_branding_panel.dart';

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

  void _submitLogin() {
    if (!_controller.isLoading) {
      _controller.login(
        context: context,
        email: _emailController.text,
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      endDrawer: const LoginSetting(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 850;

          if (isDesktop) {
            return _buildDesktopLayout(context, l10n, colorScheme, textTheme);
          }

          return _buildMobileLayout(context, l10n, colorScheme, textTheme);
        },
      ),
    );
  }

  /// Preserved mobile view for phones and narrow viewport devices.
  Widget _buildMobileLayout(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Stack(
        children: [
          SafeArea(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              size: 64,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '${l10n.smartSpaceAppName} Admin',
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          l10n.welcomeBack,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.signInToContinue,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.left,
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
                        TextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
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
                          onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                          decoration: InputDecoration(
                            hintText: l10n.email,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
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
                          dragStartBehavior: DragStartBehavior.down,
                          mouseCursor: SystemMouseCursors.text,
                          onTap: () {
                            if (_passwordController.selection.baseOffset !=
                                _passwordController.selection.extentOffset) {
                              _passwordController.selection =
                                  TextSelection.collapsed(
                                    offset: _passwordController
                                        .selection
                                        .extentOffset,
                                  );
                            }
                          },
                          onSubmitted: (_) => _submitLogin(),
                          decoration: InputDecoration(
                            hintText: l10n.password,
                            border: const OutlineInputBorder(),
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
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
                                ),
                                Text(l10n.rememberMe),
                              ],
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push(RouterPath.forgotPassword),
                              child: Text(l10n.forgotPassword),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _controller.isLoading ? null : _submitLogin,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _controller.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n.login,
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

  /// Modern responsive desktop layout with high-trust civic brand showcase and constrained form container.
  Widget _buildDesktopLayout(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        // Left Column: Civic Administration Brand Showcase
        Expanded(
          flex: 5,
          child: AuthBrandingPanel(
            badgeText: l10n.adminPortalBadge,
            badgeIcon: Icons.verified_user_outlined,
            title: '${l10n.smartSpaceAppName} Admin',
            subtitle: l10n.adminPortalSubtitle,
            highlights: [
              AuthHighlightItem(
                icon: Icons.insights_rounded,
                title: l10n.adminFeatureRealtime,
                description: l10n.adminFeatureRealtimeDesc,
              ),
              AuthHighlightItem(
                icon: Icons.alt_route_rounded,
                title: l10n.adminFeatureCoordination,
                description: l10n.adminFeatureCoordinationDesc,
              ),
              AuthHighlightItem(
                icon: Icons.security_rounded,
                title: l10n.adminFeatureSecurity,
                description: l10n.adminFeatureSecurityDesc,
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
                // Top Settings bar
                Positioned(
                  top: 24,
                  right: 32,
                  child: Builder(
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
                ),

                // Form Container (Constrained for optimal eye-tracking and typography)
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 48.0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Text(
                                l10n.welcomeBack,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.signInToContinue,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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

                              // Email Label & Field
                              Text(
                                l10n.email,
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                dragStartBehavior: DragStartBehavior.down,
                                mouseCursor: SystemMouseCursors.text,
                                onTap: () {
                                  if (_emailController.selection.baseOffset !=
                                      _emailController.selection.extentOffset) {
                                    _emailController.selection =
                                        TextSelection.collapsed(
                                          offset: _emailController
                                              .selection
                                              .extentOffset,
                                        );
                                  }
                                },
                                onSubmitted: (_) =>
                                    _passwordFocusNode.requestFocus(),
                                decoration: InputDecoration(
                                  hintText: l10n.email,
                                  prefixIcon: Icon(
                                    Icons.alternate_email_rounded,
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
                              ),
                              const SizedBox(height: 20),

                              // Password Label & Field
                              Text(
                                l10n.password,
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                dragStartBehavior: DragStartBehavior.down,
                                mouseCursor: SystemMouseCursors.text,
                                onTap: () {
                                  if (_passwordController.selection.baseOffset !=
                                      _passwordController.selection.extentOffset) {
                                    _passwordController.selection =
                                        TextSelection.collapsed(
                                          offset: _passwordController
                                              .selection
                                              .extentOffset,
                                        );
                                  }
                                },
                                onSubmitted: (_) => _submitLogin(),
                                decoration: InputDecoration(
                                  hintText: l10n.password,
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
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: colorScheme.onSurfaceVariant,
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

                              // Options: Remember Me & Forgot Password
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          onChanged: _controller.isLoading
                                              ? null
                                              : (value) {
                                                  setState(() {
                                                    _rememberMe =
                                                        value ?? false;
                                                  });
                                                },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.rememberMe,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () => context.push(
                                      RouterPath.forgotPassword,
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: colorScheme.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.forgotPassword,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Login Submit Button
                              FilledButton(
                                onPressed: _controller.isLoading
                                    ? null
                                    : _submitLogin,
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
                                child: _controller.isLoading
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: colorScheme.onPrimary,
                                        ),
                                      )
                                    : Text(
                                        l10n.login,
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
