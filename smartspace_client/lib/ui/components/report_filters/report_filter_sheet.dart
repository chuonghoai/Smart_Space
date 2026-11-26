import 'package:flutter/material.dart';

/// Một lựa chọn trong [showReportFilterSheet]. [value] có thể là `null` (thường là "Tất cả").
class ReportFilterOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const ReportFilterOption({required this.value, required this.label, this.icon});
}

/// Bottom sheet chọn một giá trị cho một chiều lọc. Chạm vào lựa chọn là áp dụng và đóng sheet
/// (không cần nút "Áp dụng"); đóng sheet bằng vuốt/chạm ngoài thì giữ nguyên lựa chọn cũ.
/// [onSelected] được gọi cả khi chạm lại lựa chọn đang chọn (vd. "Khoảng ngày…" để đổi ngày);
/// nơi nhận tự bỏ qua giá trị không đổi.
Future<void> showReportFilterSheet<T>({
  required BuildContext context,
  required String title,
  required List<ReportFilterOption<T>> options,
  required T selected,
  required ValueChanged<T> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => _ReportFilterSheet<T>(
      title: title,
      options: options,
      selected: selected,
      onSelected: (value) {
        Navigator.of(sheetContext).pop();
        onSelected(value);
      },
    ),
  );
}

class _ReportFilterSheet<T> extends StatelessWidget {
  final String title;
  final List<ReportFilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const _ReportFilterSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  for (final option in options)
                    ListTile(
                      minTileHeight: 52,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      selected: option.value == selected,
                      selectedColor: colorScheme.primary,
                      leading: option.icon == null ? null : Icon(option.icon, size: 20),
                      title: Text(
                        option.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: option.value == selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: option.value == selected ? const Icon(Icons.check_rounded, size: 20) : null,
                      onTap: () => onSelected(option.value),
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
