import 'package:flutter/material.dart';
import 'package:mobile_shared/l10n/generated/shared_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatCallBottomSheet extends StatelessWidget {
  final String partnerName;
  final String? partnerPhone;
  final bool canCellularCall;
  final bool canFreeCall;
  final String? cellularCallDisabledReason;
  final String? freeCallDisabledReason;
  final VoidCallback? onFreeCallTap;
  final String? titleText;
  final String? cellularCallTitle;
  final String? cellularCallDesc;
  final String? freeCallTitle;
  final String? freeCallDesc;
  final String? phoneNotAvailableText;

  const ChatCallBottomSheet({
    super.key,
    required this.partnerName,
    this.partnerPhone,
    this.canCellularCall = true,
    this.canFreeCall = true,
    this.cellularCallDisabledReason,
    this.freeCallDisabledReason,
    this.onFreeCallTap,
    this.titleText,
    this.cellularCallTitle,
    this.cellularCallDesc,
    this.freeCallTitle,
    this.freeCallDesc,
    this.phoneNotAvailableText,
  });

  static Future<void> show(
    BuildContext context, {
    required String partnerName,
    String? partnerPhone,
    bool canCellularCall = true,
    bool canFreeCall = true,
    String? cellularCallDisabledReason,
    String? freeCallDisabledReason,
    VoidCallback? onFreeCallTap,
    String? titleText,
    String? cellularCallTitle,
    String? cellularCallDesc,
    String? freeCallTitle,
    String? freeCallDesc,
    String? phoneNotAvailableText,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ChatCallBottomSheet(
        partnerName: partnerName,
        partnerPhone: partnerPhone,
        canCellularCall: canCellularCall,
        canFreeCall: canFreeCall,
        cellularCallDisabledReason: cellularCallDisabledReason,
        freeCallDisabledReason: freeCallDisabledReason,
        onFreeCallTap: onFreeCallTap,
        titleText: titleText,
        cellularCallTitle: cellularCallTitle,
        cellularCallDesc: cellularCallDesc,
        freeCallTitle: freeCallTitle,
        freeCallDesc: freeCallDesc,
        phoneNotAvailableText: phoneNotAvailableText,
      ),
    );
  }

  bool get _hasValidPhone {
    final phone = partnerPhone?.trim();
    return canCellularCall && phone != null && phone.isNotEmpty;
  }

  Future<void> _makePhoneCall(BuildContext context, SharedLocalizations l10n) async {
    final fallbackMsg = phoneNotAvailableText ??
        cellularCallDisabledReason ??
        l10n.callCellularUnavailable;
    Navigator.of(context).pop();
    final phone = partnerPhone?.trim();
    if (!_hasValidPhone || phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fallbackMsg),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fallbackMsg),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleFreeCallTap(BuildContext context, SharedLocalizations l10n) {
    Navigator.of(context).pop();
    if (!canFreeCall || onFreeCallTap == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(freeCallDisabledReason ?? l10n.callFreeUnavailable),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    onFreeCallTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = SharedLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    final resolvedTitle = titleText ?? l10n.callOptionsTitle;
    final resolvedCellularTitle = cellularCallTitle ?? l10n.callCellularTitle;
    final resolvedCellularDesc = _hasValidPhone
        ? partnerPhone!.trim()
        : (cellularCallDisabledReason ??
            phoneNotAvailableText ??
            cellularCallDesc ??
            l10n.callCellularUnavailable);
    final resolvedFreeTitle = freeCallTitle ?? l10n.callFreeTitle;
    final resolvedFreeDesc = canFreeCall
        ? (freeCallDesc ?? l10n.callFreeVoiceDesc)
        : (freeCallDisabledReason ?? l10n.callFreeUnavailable);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      partnerName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Option 1: Regular Cellular Call
              _CallOptionTile(
                enabled: _hasValidPhone,
                icon: Icons.phone_outlined,
                iconBg: colorScheme.primaryContainer.withValues(alpha: 0.8),
                iconColor: colorScheme.onPrimaryContainer,
                title: resolvedCellularTitle,
                subtitle: resolvedCellularDesc,
                onTap: () => _makePhoneCall(context, l10n),
              ),
              const SizedBox(height: 10),

              // Option 2: Free WebRTC Call
              _CallOptionTile(
                enabled: canFreeCall && onFreeCallTap != null,
                icon: Icons.call_rounded,
                iconBg: colorScheme.tertiaryContainer.withValues(alpha: 0.8),
                iconColor: colorScheme.onTertiaryContainer,
                title: resolvedFreeTitle,
                subtitle: resolvedFreeDesc,
                onTap: () => _handleFreeCallTap(context, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallOptionTile extends StatelessWidget {
  final bool enabled;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CallOptionTile({
    required this.enabled,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? Colors.transparent : cs.surfaceContainerLow,
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: enabled ? 0.5 : 0.3),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: enabled ? iconBg : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: enabled ? iconColor : cs.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

