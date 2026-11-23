import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
import 'package:smartspace_admin/features/map/models/spatial_analytics_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class SpatialHotspotPanel extends ConsumerWidget {
  final ValueChanged<SpatialHotspotItem> onHotspotTap;
  final VoidCallback? onClose;
  final bool isBottomSheet;

  const SpatialHotspotPanel({
    super.key,
    required this.onHotspotTap,
    this.onClose,
    this.isBottomSheet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = AppSemanticColors.of(context);
    final analyticsAsync = ref.watch(spatialAnalyticsProvider);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
          child: Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 18, color: semantic.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.spatialHotspotsTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    analyticsAsync.maybeWhen(
                      data: (res) => res.acceleratingHotspots > 0
                          ? Text(
                              l10n.spatialHotspotsAcceleratingCount(
                                res.acceleratingHotspots,
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: semantic.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : const SizedBox.shrink(),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: analyticsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '$e',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
              ),
            ),
            data: (data) {
              if (data.hotspots.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l10n.spatialHotspotsEmpty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: data.hotspots.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _HotspotRow(
                  rank: index + 1,
                  item: data.hotspots[index],
                  onTap: () => onHotspotTap(data.hotspots[index]),
                ),
              );
            },
          ),
        ),
      ],
    );

    if (isBottomSheet) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: content,
        ),
      );
    }

    return Material(
      color: cs.surface.withValues(alpha: 0.96),
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 316,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
        ),
        child: content,
      ),
    );
  }
}

class _HotspotRow extends StatelessWidget {
  final int rank;
  final SpatialHotspotItem item;
  final VoidCallback onTap;

  const _HotspotRow({
    required this.rank,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = AppSemanticColors.of(context);
    final fmt = NumberFormat('#,##0.#',
        Localizations.localeOf(context).toLanguageTag());

    final shortId = item.h3Index.length > 6
        ? item.h3Index.substring(item.h3Index.length - 6)
        : item.h3Index;
    final title = (item.sampleAddress != null && item.sampleAddress!.isNotEmpty)
        ? item.sampleAddress!
        : l10n.spatialHotspotFallbackName(shortId);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (item.isAccelerating ? cs.error : cs.primary)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#$rank',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: item.isAccelerating ? cs.error : cs.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.spatialHotspotStats(
                      item.countLast30d,
                      fmt.format(item.prev90dAvg30d),
                      item.pendingCount,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (item.isAccelerating)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            l10n.spatialHotspotAcceleratingBadge,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cs.error,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: semantic.warning.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          l10n.spatialHotspotRiskScore(item.riskScore),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: semantic.warning,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.my_location_rounded,
                size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
