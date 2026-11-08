import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatCallBottomSheet extends StatelessWidget {
  final String partnerName;
  final String? partnerPhone;
  final String titleText;
  final String cellularCallTitle;
  final String cellularCallDesc;
  final String freeCallTitle;
  final String freeCallDesc;
  final String comingSoonText;
  final String phoneNotAvailableText;
  final String freeCallComingSoonText;

  const ChatCallBottomSheet({
    super.key,
    required this.partnerName,
    this.partnerPhone,
    this.titleText = 'Tùy chọn cuộc gọi',
    this.cellularCallTitle = 'Gọi điện qua di động',
    this.cellularCallDesc = 'Mở ứng dụng gọi điện mặc định',
    this.freeCallTitle = 'Gọi miễn phí qua ứng dụng',
    this.freeCallDesc = 'Tính năng đang được phát triển',
    this.comingSoonText = 'Sắp ra mắt',
    this.phoneNotAvailableText = 'Số điện thoại không khả dụng',
    this.freeCallComingSoonText = 'Tính năng gọi miễn phí qua internet đang được phát triển',
  });

  static Future<void> show(
    BuildContext context, {
    required String partnerName,
    String? partnerPhone,
    String? titleText,
    String? cellularCallTitle,
    String? cellularCallDesc,
    String? freeCallTitle,
    String? freeCallDesc,
    String? comingSoonText,
    String? phoneNotAvailableText,
    String? freeCallComingSoonText,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ChatCallBottomSheet(
        partnerName: partnerName,
        partnerPhone: partnerPhone,
        titleText: titleText ?? 'Tùy chọn cuộc gọi',
        cellularCallTitle: cellularCallTitle ?? 'Gọi điện qua di động',
        cellularCallDesc: cellularCallDesc ?? 'Mở ứng dụng gọi điện mặc định',
        freeCallTitle: freeCallTitle ?? 'Gọi miễn phí qua ứng dụng',
        freeCallDesc: freeCallDesc ?? 'Tính năng đang được phát triển',
        comingSoonText: comingSoonText ?? 'Sắp ra mắt',
        phoneNotAvailableText: phoneNotAvailableText ?? 'Số điện thoại không khả dụng',
        freeCallComingSoonText: freeCallComingSoonText ?? 'Tính năng gọi miễn phí qua internet đang được phát triển',
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    Navigator.of(context).pop();
    final phone = partnerPhone?.trim();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(phoneNotAvailableText),
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
            content: Text(phoneNotAvailableText),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onFreeCallTap(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(freeCallComingSoonText),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
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
                      titleText,
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

              // Option 1: Cellular Call
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _makePhoneCall(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.phone_outlined,
                            color: colorScheme.onPrimaryContainer,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cellularCallTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (partnerPhone != null && partnerPhone!.trim().isNotEmpty)
                                    ? partnerPhone!
                                    : cellularCallDesc,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Option 2: Free In-App Call
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _onFreeCallTap(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.headset_mic_outlined,
                            color: colorScheme.onTertiaryContainer,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      freeCallTitle,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      comingSoonText,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                freeCallDesc,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

