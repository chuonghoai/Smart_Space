import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_client/features/sos/providers/sos_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/mobile/sos/widgets/sos_slide_button.dart';

/// Khối SOS ở trang chủ: thanh trượt khi chưa có SOS, dải "đang hoạt động" khi đã gửi.
/// Mở lại app khi SOS còn mở thì khôi phục và tiếp tục chia sẻ vị trí.
class SosHomeCard extends ConsumerStatefulWidget {
  const SosHomeCard({super.key});

  @override
  ConsumerState<SosHomeCard> createState() => _SosHomeCardState();
}

class _SosHomeCardState extends ConsumerState<SosHomeCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!ref.read(sosProvider).isLoaded) {
        await ref.read(sosProvider.notifier).loadActive();
      }
      _resumeTracking();
    });
  }

  void _resumeTracking() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ref.read(sosProvider.notifier).ensureTracking(
          notificationTitle: l10n.sosTrackingNotifTitle,
          notificationText: l10n.sosTrackingNotifText,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasOpen = ref.watch(sosProvider.select((s) => s.hasOpen));

    if (hasOpen) {
      return Material(
        color: scheme.errorContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.error.withValues(alpha: 0.45)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(RouterPath.sosActive),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sos, color: scheme.onError, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.sosActiveBanner,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.sosActiveBannerHint,
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onErrorContainer),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: scheme.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.sosSlideSemantics,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push(RouterPath.emergencyContacts),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(
                  Icons.contact_phone_outlined,
                  size: 16,
                  color: scheme.primary,
                ),
                label: Text(
                  l10n.emergencyContacts,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SosSlideButton(onActivated: () => context.push(RouterPath.sosCountdown)),
          const SizedBox(height: 8),
          Text(
            l10n.sosSlideHint,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
