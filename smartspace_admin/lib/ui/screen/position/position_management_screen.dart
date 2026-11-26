import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/features/position/application/position_providers.dart';
import 'package:smartspace_admin/features/position/data/position_repository.dart';
import 'package:smartspace_admin/features/position/models/position_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/position/widgets/position_table_view.dart';

/// Quản lý chức vụ: danh sách
class PositionManagementScreen extends ConsumerWidget {
  const PositionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(positionListProvider);

    return AppLayout(
      child: RefreshIndicator(
        onRefresh: () async => ref.refresh(positionListProvider.future),
        child: ListView(
          padding: EdgeInsets.all(kIsWeb ? 24 : 16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (kIsWeb && async.valueOrNull != null)
                        ? '${l10n.managePositions} · ${async.valueOrNull!.length}'
                        : l10n.managePositions,
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
                    label: Text(l10n.addPosition),
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
                    onPressed: () => ref.invalidate(positionListProvider),
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
                        l10n.emptyPositionList,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                void edit(PositionModel p) =>
                    _showForm(context, ref, l10n, editing: p);
                void del(PositionModel p) =>
                    _confirmDelete(context, ref, l10n, p);
                if (kIsWeb) {
                  return PositionWebView(
                    items: items,
                    onEdit: edit,
                    onDelete: del,
                  );
                }
                return Column(
                  children: [
                    for (final p in items)
                      _PositionTile(
                        position: p,
                        onEdit: () => edit(p),
                        onDelete: () => del(p),
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
    PositionModel p,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deletePosition),
        content: Text('${l10n.deletePositionConfirm}\n${p.name}'),
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
            child: Text(l10n.deletePosition),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final res = await positionRepository.deletePosition(p.id);
    if (res.success) {
      ref.invalidate(positionListProvider);
      ref.invalidate(activePositionsProvider);
      Toast.show(ToastType.success, l10n.positionDeleteSuccess);
    } else {
      // message đã được backend localize (vd: chức vụ đang được gán cho staff)
      Toast.show(ToastType.error, res.message);
    }
  }

  void _showForm(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    PositionModel? editing,
  }) {
    showDialog(
      context: context,
      builder: (_) => _PositionFormDialog(editing: editing, ref: ref),
    );
  }
}

class _PositionTile extends StatelessWidget {
  final PositionModel position;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PositionTile({
    required this.position,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Opacity(
      opacity: position.active ? 1 : 0.6,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                child: Icon(
                  Icons.workspace_premium_outlined,
                  color: cs.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      position.code,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (position.description != null &&
                        position.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        position.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _Pill(
                          text: l10n.positionStaffCount(position.staffCount),
                          bg: cs.primaryContainer,
                          fg: cs.onPrimaryContainer,
                        ),
                        if (!position.active)
                          _Pill(
                            text: l10n.positionInactive,
                            bg: cs.errorContainer,
                            fg: cs.onErrorContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.editPosition,
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: l10n.deletePosition,
                icon: Icon(Icons.delete_outline, color: cs.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Pill({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

class _PositionFormDialog extends StatefulWidget {
  final PositionModel? editing;
  final WidgetRef ref;

  const _PositionFormDialog({this.editing, required this.ref});

  @override
  State<_PositionFormDialog> createState() => _PositionFormDialogState();
}

class _PositionFormDialogState extends State<_PositionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.editing?.name);
  late final _code = TextEditingController(text: widget.editing?.code);
  late final _desc = TextEditingController(text: widget.editing?.description);
  late bool _active = widget.editing?.active ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final desc = _desc.text.trim().isEmpty ? null : _desc.text.trim();
    final editing = widget.editing;
    final res = editing == null
        ? await positionRepository.createPosition(
            code: _code.text.trim(),
            name: _name.text.trim(),
            description: desc,
          )
        : await positionRepository.updatePosition(
            id: editing.id,
            code: _code.text.trim(),
            name: _name.text.trim(),
            description: desc,
            active: _active,
          );

    if (!mounted) return;
    setState(() => _saving = false);

    if (res.success) {
      widget.ref.invalidate(positionListProvider);
      widget.ref.invalidate(activePositionsProvider);
      Navigator.pop(context);
      Toast.show(ToastType.success, l10n.positionSaveSuccess);
    } else {
      Toast.show(ToastType.error, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(8));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.editing == null ? l10n.addPosition : l10n.editPosition,
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '${l10n.positionName} *',
                    border: border,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.positionNameRequired
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '${l10n.positionCode} *',
                    border: border,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.positionCodeRequired
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.positionDescription,
                    border: border,
                  ),
                ),
                if (widget.editing != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.positionActiveLabel),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
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
