import 'package:flutter/material.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import '../../../shared/login_setting/login_setting.dart';

class WebAuthLayout extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;
  final bool showBackButton;

  const WebAuthLayout({
    super.key,
    required this.child,
    this.onBack,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      endDrawer: const LoginSetting(),
      body: Stack(
        children: [
          Row(
            children: [
              // Left Side: Branding / Visuals
              Expanded(
                flex: 5,
                child: Container(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 120,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        l10n.smartSpaceAppName,
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          l10n.splashTagline,
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Side: Form
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48.0,
                      vertical: 64.0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Back Button Positioned at the top left
          if (showBackButton)
            Positioned(
              top: 24,
              left: 32,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack,
              ),
            ),

          // Settings Drawer Icon Positioned at the top right
          Positioned(
            top: 24,
            right: 32,
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
        ],
      ),
    );
  }
}
