import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/core/localization/locale_provider.dart';
import 'package:mobile_shared/core/theme/theme_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/mobile/settings/settings_controller.dart';
import 'package:smartspace_client/ui/shared/image/app_network_image.dart';

class MobileSettingsScreen extends StatefulWidget {
  const MobileSettingsScreen({super.key});

  @override
  State<MobileSettingsScreen> createState() => _MobileSettingsScreenState();
}

class _MobileSettingsScreenState extends State<MobileSettingsScreen> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
    _controller.loadUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return ListView(
            children: [
              // Profile Card
              _buildProfileCard(theme, l10n),
              const Divider(height: 1),

              // Nhóm 1: Tài khoản
              _buildSectionHeader(theme, l10n.accountSection),
              _buildItem(
                theme: theme,
                icon: Icons.share_outlined,
                label: l10n.shareHistory,
              ),
              _buildItem(
                theme: theme,
                icon: Icons.password,
                label: l10n.changePassword,
                onTap: () => context.push(RouterPath.changePassword),
              ),
              _buildItem(
                theme: theme,
                icon: Icons.phone_android_outlined,
                label: l10n.manageDevices,
                onTap: () => context.push(RouterPath.manageDevices),
              ),
              _buildItem(
                theme: theme,
                icon: Icons.notifications_outlined,
                label: l10n.notificationSettings,
              ),
              const Divider(height: 1),

              // Nhóm 2: Ứng dụng
              _buildSectionHeader(theme, l10n.appSection),
              ListenableBuilder(
                listenable: localeProvider,
                builder: (context, _) {
                  final currentLang = localeProvider.locale.languageCode == 'vi'
                      ? l10n.vietnamese
                      : l10n.english;
                  return _buildItem(
                    theme: theme,
                    icon: Icons.language_outlined,
                    label: l10n.language,
                    trailing: Text(
                      currentLang,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () => _showLanguagePicker(context, l10n, theme),
                  );
                },
              ),
              ListenableBuilder(
                listenable: themeProvider,
                builder: (context, _) {
                  final label = switch (themeProvider.themeMode) {
                    ThemeMode.light => l10n.themeLight,
                    ThemeMode.dark => l10n.themeDark,
                    ThemeMode.system => l10n.themeSystem,
                  };
                  return _buildItem(
                    theme: theme,
                    icon: Icons.palette_outlined,
                    label: l10n.theme,
                    trailing: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () => _showThemePicker(context, l10n, theme),
                  );
                },
              ),
              _buildItem(
                theme: theme,
                icon: Icons.description_outlined,
                label: l10n.termsOfService,
              ),
              _buildItem(
                theme: theme,
                icon: Icons.shield_outlined,
                label: l10n.privacyPolicy,
              ),
              _buildItem(
                theme: theme,
                icon: null,
                label: l10n.appVersion,
                trailing: Text(
                  '1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Divider(height: 1),

              // Nhóm 3: Hỗ trợ
              _buildSectionHeader(theme, l10n.supportSection),
              _buildItem(
                theme: theme,
                icon: null,
                label: l10n.supportHotline,
                trailing: Text(
                  '1900.0368',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildItem(
                theme: theme,
                icon: Icons.menu_book_outlined,
                label: l10n.userGuide,
              ),
              _buildItem(
                theme: theme,
                icon: Icons.help_outline,
                label: l10n.faq,
              ),
              const Divider(height: 1),

              // Đăng xuất
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: _controller.isLoading
                      ? null
                      : () => _showLogoutDialog(context, l10n, theme),
                  icon: Icon(Icons.logout, color: theme.colorScheme.error),
                  label: Text(
                    l10n.logout,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: theme.colorScheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildProfileCard(ThemeData theme, AppLocalizations l10n) {
    final user = _controller.user;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          AppNetworkImage(
            url: user?.avatarUrl,
            width: 56,
            height: 56,
            isCircle: true,
            errorWidget: CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.person, color: theme.colorScheme.onPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullname ?? l10n.user,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              context.push(RouterPath.editProfile);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildItem({
    required ThemeData theme,
    required IconData? icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, color: theme.colorScheme.onSurfaceVariant)
          : null,
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing:
          trailing ??
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap ?? () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.language,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              RadioListTile<String>(
                title: Text(l10n.vietnamese),
                value: 'vi',
                groupValue: localeProvider.locale.languageCode,
                onChanged: (v) {
                  if (v != null) localeProvider.setLocale(Locale(v));
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                title: Text(l10n.english),
                value: 'en',
                groupValue: localeProvider.locale.languageCode,
                onChanged: (v) {
                  if (v != null) localeProvider.setLocale(Locale(v));
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showThemePicker(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.theme,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.themeLight),
                secondary: const Icon(Icons.light_mode_outlined),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (v) {
                  if (v != null) themeProvider.setThemeMode(v);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.themeDark),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (v) {
                  if (v != null) themeProvider.setThemeMode(v);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.themeSystem),
                secondary: const Icon(Icons.brightness_auto_outlined),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (v) {
                  if (v != null) themeProvider.setThemeMode(v);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _controller.logout();
            },
            child: Text(
              l10n.logout,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
