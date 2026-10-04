import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/position/application/position_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

/// Chip hiển thị chức vụ — dùng chung cho danh sách staff và màn phân công.
class PositionChip extends StatelessWidget {
  final String name;
  const PositionChip({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_outlined,
              size: 12, color: cs.onSecondaryContainer),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSecondaryContainer,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hàng chip lọc theo chức vụ (null = tất cả). Dùng khi phân công staff.
class PositionFilterChips extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const PositionFilterChips({
    super.key,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final positions = ref.watch(activePositionsProvider).valueOrNull ?? [];
    if (positions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(l10n.allPositions),
              selected: selectedId == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          for (final p in positions)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p.name),
                selected: selectedId == p.id,
                onSelected: (_) => onChanged(p.id),
              ),
            ),
        ],
      ),
    );
  }
}
