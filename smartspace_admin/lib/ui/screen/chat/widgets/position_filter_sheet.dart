import 'package:flutter/material.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class PositionFilterSheet extends StatefulWidget {
  final List<PositionModel> positions;
  final Set<String> initialSelected;

  const PositionFilterSheet({
    super.key,
    required this.positions,
    required this.initialSelected,
  });

  static Future<Set<String>?> show(
    BuildContext context, {
    required List<PositionModel> positions,
    required Set<String> initialSelected,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PositionFilterSheet(
        positions: positions,
        initialSelected: initialSelected,
      ),
    );
  }

  @override
  State<PositionFilterSheet> createState() => _PositionFilterSheetState();
}

class _PositionFilterSheetState extends State<PositionFilterSheet> {
  late Set<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = Set<String>.from(widget.initialSelected);
  }

  void _toggle(String id) {
    setState(() {
      if (_tempSelected.contains(id)) {
        _tempSelected.remove(id);
      } else {
        _tempSelected.add(id);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _tempSelected.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.filterPositionSheetTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_tempSelected.isNotEmpty)
                    TextButton(
                      onPressed: _clearAll,
                      child: Text(l10n.clearFilters),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Position list
            Flexible(
              child: widget.positions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          l10n.noPositionsAvailable,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      itemCount: widget.positions.length,
                      itemBuilder: (context, index) {
                        final pos = widget.positions[index];
                        final isSelected = _tempSelected.contains(pos.id);

                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(
                            pos.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          subtitle: pos.description != null && pos.description!.isNotEmpty
                              ? Text(
                                  pos.description!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          activeColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onChanged: (_) => _toggle(pos.id),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            // Actions: Hủy & Áp dụng
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _tempSelected),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.applyFilter),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
