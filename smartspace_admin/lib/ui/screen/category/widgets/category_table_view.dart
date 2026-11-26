import 'package:flutter/material.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/core/utils/report_category_helper.dart';
import 'package:smartspace_admin/features/category/models/category_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/shared/position/position_widgets.dart';

String categorySeverityText(String severity, AppLocalizations l10n) {
  return switch (severity.toLowerCase()) {
    'critical' => l10n.severityCritical,
    'high' => l10n.severityHigh,
    'medium' => l10n.severityMedium,
    _ => l10n.severityLow,
  };
}

Color categorySeverityColor(BuildContext context, String severity) {
  final semantic = AppSemanticColors.of(context);
  final cs = Theme.of(context).colorScheme;
  return switch (severity.toLowerCase()) {
    'critical' => cs.error,
    'high' => semantic.warning,
    'medium' => semantic.info,
    _ => semantic.success,
  };
}

class CategoryWebView extends StatelessWidget {
  final List<CategoryModel> items;
  final void Function(CategoryModel) onEdit;
  final void Function(CategoryModel) onDelete;

  const CategoryWebView({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final activeCount = items.where((c) => c.active).length;
    final mappedCount = items.where((c) => c.positions.isNotEmpty).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI strip — flat surface, 1px hairline divisions, tabular typography only
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _KpiCell(
                    label: l10n.totalCategories,
                    value: '${items.length}',
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
                Expanded(
                  child: _KpiCell(
                    label: l10n.categoryActiveLabel,
                    value: '$activeCount',
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
                Expanded(
                  child: _KpiCell(
                    label: l10n.categoriesMappedPositions,
                    value: '$mappedCount / ${items.length}',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _CategoryTable(items: items, onEdit: onEdit, onDelete: onDelete),
      ],
    );
  }
}

class _KpiCell extends StatelessWidget {
  final String label;
  final String value;

  const _KpiCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTable extends StatelessWidget {
  final List<CategoryModel> items;
  final void Function(CategoryModel) onEdit;
  final void Function(CategoryModel) onDelete;

  const _CategoryTable({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = AppSemanticColors.of(context);

    Widget header(String text, {Alignment align = Alignment.centerLeft}) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Align(
            alignment: align,
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        );

    Widget cell(Widget child, {Alignment align = Alignment.centerLeft}) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Align(alignment: align, child: child),
        );

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, box) {
          const minWidth = 1040.0;
          final tableWidth = box.maxWidth > minWidth ? box.maxWidth : minWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FlexColumnWidth(2.4),
                  1: FixedColumnWidth(150),
                  2: FixedColumnWidth(130),
                  3: FlexColumnWidth(2.6),
                  4: FixedColumnWidth(100),
                  5: FixedColumnWidth(150),
                  6: FixedColumnWidth(110),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: theme.dividerColor,
                    width: 0.8,
                  ),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: cs.surfaceContainerLow),
                    children: [
                      header(l10n.categoryNameVi),
                      header(l10n.categoryCode),
                      header(l10n.categoryDefaultSeverity),
                      header(l10n.categoryPositionsLabel),
                      header(l10n.categoryReportCountLabel,
                          align: Alignment.centerRight),
                      header(l10n.statusLabel),
                      header(l10n.actionsColumn),
                    ],
                  ),
                  for (final c in items)
                    TableRow(
                      children: [
                        cell(
                          Row(
                            children: [
                              Icon(
                                ReportCategoryHelper.iconFor(c.iconKey),
                                size: 18,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.nameVi,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      c.nameEn,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        cell(
                          Text(
                            c.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        cell(
                          _SeverityBadge(severity: c.defaultSeverity),
                        ),
                        cell(
                          c.positions.isEmpty
                              ? Text(
                                  l10n.categoryNoPositionsMapped,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: semantic.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final pos in c.positions)
                                      PositionChip(name: pos.name),
                                  ],
                                ),
                        ),
                        cell(
                          Text(
                            '${c.reportCount}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          align: Alignment.centerRight,
                        ),
                        cell(_CategoryStatusPill(active: c.active)),
                        cell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: l10n.editCategory,
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => onEdit(c),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: l10n.deleteCategory,
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: cs.error,
                                ),
                                onPressed: () => onDelete(c),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = categorySeverityColor(context, severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        categorySeverityText(severity, l10n),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CategoryStatusPill extends StatelessWidget {
  final bool active;
  const _CategoryStatusPill({required this.active});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final fg = active ? semantic.success : cs.error;
    final bg = fg.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.check_circle : Icons.block, size: 14, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              active ? l10n.categoryActiveLabel : l10n.categoryInactive,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
