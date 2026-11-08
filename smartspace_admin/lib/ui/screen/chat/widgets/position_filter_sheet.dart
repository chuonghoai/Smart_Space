import 'package:flutter/material.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class PositionFilterSheet extends StatelessWidget {
  final List<PositionModel> positions;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;
  final VoidCallback onApply;

  const PositionFilterSheet({
    super.key,
    required this.positions,
    required this.selectedIds,
    required this.onToggle,
    required this.onClear,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required List<PositionModel> positions,
    required Set<String> selectedIds,
    required ValueChanged<String> onToggle,
    required VoidCallback onClear,
    required VoidCallback onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return PositionFilterSheet(
            positions: positions,
            selectedIds: selectedIds,
            onToggle: (id) {
              onToggle(id);
              setModalState(() {});
            },
            onClear: () {
              onClear();
              setModalState(() {});
            },
            onApply: () {
              Navigator.pop(ctx);
              onApply();
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                  if (selectedIds.isNotEmpty)
                    TextButton(
                      onPressed: onClear,
                      child: Text(l10n.resetFilter),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Position list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: positions.length,
                itemBuilder: (context, index) {
                  final pos = positions[index];
                  final isSelected = selectedIds.contains(pos.id);

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
                    onChanged: (_) => onToggle(pos.id),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // Apply button
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: onApply,
                child: Text(l10n.applyFilter),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

