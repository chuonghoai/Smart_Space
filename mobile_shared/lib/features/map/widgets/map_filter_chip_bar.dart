import 'package:flutter/material.dart';

/// Một lựa chọn trên [MapFilterChipBar]; [label] đã được L10n bởi app gọi.
class MapFilterChipOption<T> {
  final T value;
  final String label;

  const MapFilterChipOption({required this.value, required this.label});
}

/// Hàng chip lọc nổi trên bản đồ (chọn một), cuộn ngang khi không đủ chỗ.
/// Chip có nền đặc theo theme → chữ không đặt trực tiếp lên bản đồ, đọc được ở cả Dark/Light.
class MapFilterChipBar<T> extends StatelessWidget {
  final List<MapFilterChipOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const MapFilterChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.value == selected;
          return Center(
            child: ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (_) => onSelected(option.value),
              showCheckmark: false,
              elevation: 3,
              pressElevation: 1,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
              backgroundColor: colorScheme.surface,
              selectedColor: colorScheme.primaryContainer,
              side: BorderSide(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }
}
