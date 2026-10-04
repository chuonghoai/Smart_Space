import 'package:flutter/material.dart';
import 'package:smartspace_admin/features/position/models/position_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

/// Web: KPI tổng quan lớn hơn + bảng chức vụ chuẩn design.md, chống tràn 100%.
class PositionWebView extends StatelessWidget {
  final List<PositionModel> items;
  final void Function(PositionModel) onEdit;
  final void Function(PositionModel) onDelete;

  const PositionWebView({
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
    final active = items.where((p) => p.active).length;
    final staff = items.fold<int>(0, (s, p) => s + p.staffCount);

    final cardTotal = _WebKpiCard(
      icon: Icons.workspace_premium_outlined,
      iconColor: cs.primary,
      label: l10n.totalPositions,
      value: '${items.length}',
    );
    final cardActive = _WebKpiCard(
      icon: Icons.check_circle_outline,
      iconColor: cs.secondary,
      label: l10n.positionActiveLabel,
      value: '$active',
    );
    final cardStaff = _WebKpiCard(
      icon: Icons.groups_outlined,
      iconColor: cs.tertiary,
      label: l10n.positionAssignedStaff,
      value: '$staff',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Cards: Responsive theo chiều ngang, padding & layout rộng rãi theo design.md
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: cardTotal),
                      const SizedBox(width: 16),
                      Expanded(child: cardActive),
                    ],
                  ),
                  const SizedBox(height: 16),
                  cardStaff,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: cardTotal),
                const SizedBox(width: 16),
                Expanded(child: cardActive),
                const SizedBox(width: 16),
                Expanded(child: cardStaff),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _Table(items: items, onEdit: onEdit, onDelete: onDelete),
      ],
    );
  }
}

/// KPI Card phong cách dashboard web (giống WebStaffView, chuẩn design.md)
class _WebKpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _WebKpiCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Table extends StatelessWidget {
  final List<PositionModel> items;
  final void Function(PositionModel) onEdit;
  final void Function(PositionModel) onDelete;
  const _Table({required this.items, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget h(String t) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Text(
            t,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
            ),
          ),
        );

    Widget d(Widget c) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Align(alignment: Alignment.centerLeft, child: c),
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
          const minTableWidth = 980.0;
          final tableWidth = box.maxWidth > minTableWidth ? box.maxWidth : minTableWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FlexColumnWidth(2.5),  // Tên chức vụ
                  1: FixedColumnWidth(160), // Mã chức vụ
                  2: FlexColumnWidth(3.0),  // Mô tả
                  3: FixedColumnWidth(110), // Số nhân viên
                  4: FixedColumnWidth(190), // Trạng thái (đủ rộng cho pill + chống tràn)
                  5: FixedColumnWidth(130), // Thao tác
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: theme.dividerColor, width: 0.5),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: cs.surfaceContainerLow),
                    children: [
                      h(l10n.positionName),
                      h(l10n.positionCode),
                      h(l10n.positionDescription),
                      h(l10n.staff),
                      h(l10n.statusLabel),
                      h(l10n.actionsColumn),
                    ],
                  ),
                  for (final p in items)
                    TableRow(children: [
                      d(Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      )),
                      d(Text(
                        p.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      )),
                      d(Text(
                        (p.description?.isNotEmpty ?? false) ? p.description! : '—',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      )),
                      d(Text('${p.staffCount}', style: theme.textTheme.bodyMedium)),
                      d(_Status(active: p.active)),
                      d(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: l10n.editPosition,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => onEdit(p),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: l10n.deletePosition,
                            icon: Icon(Icons.delete_outline, color: cs.error),
                            onPressed: () => onDelete(p),
                          ),
                        ],
                      )),
                    ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Icon + text + defensive Flexible để triệt để chống overflow.
class _Status extends StatelessWidget {
  final bool active;
  const _Status({required this.active});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final bg = active ? cs.primaryContainer : cs.errorContainer;
    final fg = active ? cs.onPrimaryContainer : cs.onErrorContainer;
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
              active ? l10n.positionActiveLabel : l10n.positionInactive,
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
