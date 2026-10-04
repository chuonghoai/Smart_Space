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

/// Quản lý chức vụ: danh sách + thêm/sửa/xóa. Một layout responsive cho Web & Mobile.
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
                    style: (kIsWeb
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
                  Icon(Icons.error_outline,
                      size: 48, color: theme.colorScheme.error),
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
                void del(PositionModel p) => _confirmDelete(context, ref, l10n, p);
                if (kIsWeb) {
                  return PositionWebView(items: items, onEdit: edit, onDelete: del);
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

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Tên & Mã chức vụ + Nút Thao tác
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: position.active
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    size: 20,
                    color: position.active
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        position.code,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.editPosition,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.deletePosition,
                  icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
                  onPressed: onDelete,
                ),
              ],
            ),

            // Mô tả (nếu có)
            if (position.description != null &&
                position.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                position.description!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 0.5,
              color: theme.dividerColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),

            // Footer: Số nhân viên bên TRÁI, Trạng thái hoạt động bên PHẢI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Số nhân viên (Left metadata)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.positionStaffCount(position.staffCount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                // Trạng thái hoạt động (Right status badge)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: position.active
                        ? cs.primaryContainer.withValues(alpha: 0.6)
                        : cs.errorContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        position.active
                            ? Icons.check_circle_outline
                            : Icons.block_outlined,
                        size: 13,
                        color: position.active
                            ? cs.onPrimaryContainer
                            : cs.onErrorContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        position.active
                            ? l10n.positionActiveLabel
                            : l10n.positionInactive,
                        style: TextStyle(
                          color: position.active
                              ? cs.onPrimaryContainer
                              : cs.onErrorContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
  }
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEdit = widget.editing != null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: theme.dividerColor),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ngắn gọn, có icon điểm nhấn ──────────────
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: cs.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEdit ? l10n.editPosition : l10n.addPosition,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: l10n.cancel,
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Input: Tên chức vụ ──────────────────────────────
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '${l10n.positionName} *',
                      prefixIcon: Icon(Icons.badge_outlined,
                          size: 18, color: cs.primary),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: focusedBorder,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.positionNameRequired
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // ── Input: Mã chức vụ ────────────────────────────────
                  TextFormField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: '${l10n.positionCode} *',
                      hintText: l10n.positionCodeHint,
                      prefixIcon: Icon(Icons.fingerprint_rounded,
                          size: 18, color: cs.primary),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: focusedBorder,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.positionCodeRequired
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // ── Input: Mô tả ────────────────────────────────────
                  TextFormField(
                    controller: _desc,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.positionDescription,
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.description_outlined,
                            size: 18, color: cs.primary),
                      ),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: focusedBorder,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),

                  // ── Trạng thái (Edit Mode) - Gọn gàng 1 dòng ───────
                  if (isEdit) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _active
                                ? Icons.check_circle_outline
                                : Icons.block_outlined,
                            size: 18,
                            color: _active ? cs.primary : cs.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _active
                                  ? l10n.positionActiveLabel
                                  : l10n.positionInactive,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _active ? cs.primary : cs.error,
                              ),
                            ),
                          ),
                          Switch(
                            value: _active,
                            onChanged: _saving
                                ? null
                                : (v) => setState(() => _active = v),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: theme.dividerColor.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 14),

                  // ── Action Buttons ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _saving ? null : () => _submit(l10n),
                        icon: _saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 16),
                        label: Text(
                            isEdit ? l10n.saveChanges : l10n.addPosition),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
