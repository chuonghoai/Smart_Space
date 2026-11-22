import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/features/category/application/category_providers.dart';
import 'package:smartspace_admin/features/category/data/category_repository.dart';
import 'package:smartspace_admin/features/category/models/category_model.dart';
import 'package:smartspace_admin/features/position/application/position_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/category/widgets/category_table_view.dart';
import 'package:smartspace_admin/ui/shared/position/position_widgets.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(categoryListProvider);

    return AppLayout(
      child: RefreshIndicator(
        onRefresh: () async => ref.refresh(categoryListProvider.future),
        child: ListView(
          padding: EdgeInsets.all(kIsWeb ? 24 : 16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (kIsWeb && async.valueOrNull != null)
                        ? '${l10n.manageCategories} · ${async.valueOrNull!.length}'
                        : l10n.manageCategories,
                    style:
                        (kIsWeb
                                ? theme.textTheme.headlineSmall
                                : theme.textTheme.titleLarge)
                            ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (kIsWeb)
                  FilledButton.icon(
                    onPressed: () => _showForm(context, ref, l10n),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addCategory),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else
                  IconButton.filled(
                    onPressed: () => _showForm(context, ref, l10n),
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 8),
                  Text(e.toString()),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(categoryListProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Text(
                        l10n.emptyCategoryList,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                void edit(CategoryModel c) =>
                    _showForm(context, ref, l10n, editing: c);
                void del(CategoryModel c) =>
                    _confirmDelete(context, ref, l10n, c);
                if (kIsWeb) {
                  return CategoryWebView(
                    items: items,
                    onEdit: edit,
                    onDelete: del,
                  );
                }
                return Column(
                  children: [
                    for (final c in items)
                      _CategoryTile(
                        category: c,
                        onEdit: () => edit(c),
                        onDelete: () => del(c),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    CategoryModel c,
  ) async {
    final locale = Localizations.localeOf(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteCategory),
        content: Text('${l10n.deleteCategoryConfirm}\n${c.localizedName(locale)}'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteCategory),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final res = await categoryRepository.deleteCategory(c.id);
    if (res.success) {
      ref.invalidate(categoryListProvider);
      ref.invalidate(activeCategoriesProvider);
      Toast.show(ToastType.success, l10n.categoryDeleteSuccess);
    } else {
      Toast.show(ToastType.error, res.message);
    }
  }

  void _showForm(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    CategoryModel? editing,
  }) {
    showDialog(
      context: context,
      builder: (_) => _CategoryFormDialog(editing: editing, ref: ref),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = AppSemanticColors.of(context);
    final locale = Localizations.localeOf(context);
    final sevColor = categorySeverityColor(context, category.defaultSeverity);

    return Opacity(
      opacity: category.active ? 1 : 0.6,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(
                      ReportCategoryHelper.iconFor(category.iconKey),
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.localizedName(locale),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${category.code} · ${category.nameVi} / ${category.nameEn}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.editCategory,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: l10n.deleteCategory,
                    icon: Icon(Icons.delete_outline, color: cs.error),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: sevColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      categorySeverityText(category.defaultSeverity, l10n),
                      style: TextStyle(
                        color: sevColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!category.active)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.categoryInactive,
                        style: TextStyle(
                          color: cs.onErrorContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (category.positions.isEmpty)
                    Text(
                      l10n.categoryNoPositionsMapped,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: semantic.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    for (final pos in category.positions)
                      PositionChip(name: pos.name),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFormDialog extends ConsumerStatefulWidget {
  final CategoryModel? editing;
  final WidgetRef ref;

  const _CategoryFormDialog({this.editing, required this.ref});

  @override
  ConsumerState<_CategoryFormDialog> createState() =>
      _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  static final _iconKeys = ReportCategoryHelper.iconKeys;

  final _formKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.editing?.code);
  late final _nameVi = TextEditingController(text: widget.editing?.nameVi);
  late final _nameEn = TextEditingController(text: widget.editing?.nameEn);
  late final _desc = TextEditingController(text: widget.editing?.description);
  late final _order = TextEditingController(
    text: '${widget.editing?.displayOrder ?? 0}',
  );

  late String _iconKey = widget.editing?.iconKey ?? ReportCategoryHelper.defaultIconKey;
  late String _defaultSeverity = widget.editing?.defaultSeverity ?? 'low';
  late bool _active = widget.editing?.active ?? true;
  late final Set<String> _selectedPositionIds = {
    for (final p in widget.editing?.positions ?? const <CategoryPositionRef>[])
      p.id,
  };
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _nameVi.dispose();
    _nameEn.dispose();
    _desc.dispose();
    _order.dispose();
    super.dispose();
  }

  String _iconLabel(String key, AppLocalizations l10n) {
    return switch (key) {
      'eco' => l10n.categoryIconEco,
      'construction' => l10n.categoryIconConstruction,
      'bolt' => l10n.categoryIconBolt,
      'water_drop' => l10n.categoryIconWater,
      'shield' => l10n.categoryIconShield,
      'park' => l10n.categoryIconPark,
      'traffic' => l10n.categoryIconTraffic,
      _ => l10n.categoryIconGeneral,
    };
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final desc = _desc.text.trim().isEmpty ? null : _desc.text.trim();
    final order = int.tryParse(_order.text.trim()) ?? 0;
    final editing = widget.editing;

    final res = editing == null
        ? await categoryRepository.createCategory(
            code: _code.text.trim(),
            nameVi: _nameVi.text.trim(),
            nameEn: _nameEn.text.trim(),
            description: desc,
            iconKey: _iconKey,
            defaultSeverity: _defaultSeverity,
            displayOrder: order,
            positionIds: _selectedPositionIds.toList(),
          )
        : await categoryRepository.updateCategory(
            id: editing.id,
            code: _code.text.trim(),
            nameVi: _nameVi.text.trim(),
            nameEn: _nameEn.text.trim(),
            description: desc,
            iconKey: _iconKey,
            defaultSeverity: _defaultSeverity,
            active: _active,
            displayOrder: order,
            positionIds: _selectedPositionIds.toList(),
          );

    if (!mounted) return;
    setState(() => _saving = false);

    if (res.success) {
      widget.ref.invalidate(categoryListProvider);
      widget.ref.invalidate(activeCategoriesProvider);
      Navigator.pop(context);
      Toast.show(ToastType.success, l10n.categorySaveSuccess);
    } else {
      Toast.show(ToastType.error, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(8));
    final positionsAsync = ref.watch(activePositionsProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.editing == null ? l10n.addCategory : l10n.editCategory,
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '${l10n.categoryCode} *',
                    border: border,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.categoryCodeRequired
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameVi,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '${l10n.categoryNameVi} *',
                    border: border,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.categoryNameViRequired
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameEn,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '${l10n.categoryNameEn} *',
                    border: border,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.categoryNameEnRequired
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _defaultSeverity,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.categoryDefaultSeverity,
                          border: border,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'low',
                            child: Text(l10n.severityLow),
                          ),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text(l10n.severityMedium),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text(l10n.severityHigh),
                          ),
                          DropdownMenuItem(
                            value: 'critical',
                            child: Text(l10n.severityCritical),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _defaultSeverity = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _order,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.categoryDisplayOrder,
                          border: border,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _iconKeys.contains(_iconKey)
                      ? _iconKey
                      : ReportCategoryHelper.defaultIconKey,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.categoryIconLabel,
                    border: border,
                  ),
                  items: [
                    for (final key in _iconKeys)
                      DropdownMenuItem(
                        value: key,
                        child: Row(
                          children: [
                            Icon(ReportCategoryHelper.iconFor(key), size: 18),
                            const SizedBox(width: 8),
                            Text(_iconLabel(key, l10n)),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _iconKey = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.categoryDescription,
                    border: border,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.categoryPositionsLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.categoryPositionsHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                positionsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (positions) {
                    final combined = <PositionModel>[...positions];
                    for (final refPos
                        in widget.editing?.positions ??
                            const <CategoryPositionRef>[]) {
                      if (!combined.any((p) => p.id == refPos.id)) {
                        combined.add(PositionModel(
                          id: refPos.id,
                          name: refPos.name,
                          code: refPos.code,
                          active: refPos.active,
                        ));
                      }
                    }
                    if (combined.isEmpty) {
                      return Text(
                        l10n.categoryNoActivePositions,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final pos in combined)
                          FilterChip(
                            label: Text(pos.name),
                            selected: _selectedPositionIds.contains(pos.id),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedPositionIds.add(pos.id);
                                } else {
                                  _selectedPositionIds.remove(pos.id);
                                }
                              });
                            },
                          ),
                      ],
                    );
                  },
                ),
                if (widget.editing != null) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.categoryActiveLabel),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : () => _submit(l10n),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.confirm),
        ),
      ],
    );
  }
}
