import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_client/features/reports/models/report_date_range.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/components/report_filters/report_filter_chip.dart';
import 'package:smartspace_client/ui/components/report_filters/report_filter_sheet.dart';

enum _DateMode { singleDay, range }

/// Chip lọc theo ngày tạo phản ánh: "Mọi thời gian", một ngày cụ thể, hoặc một khoảng ngày.
///
/// Tách "Một ngày" và "Khoảng ngày" thành 2 lựa chọn vì lịch chọn khoảng của Material chỉ chọn được
/// một ngày khi chạm 2 lần vào cùng ngày — người dùng khó tự phát hiện.
class ReportDateRangeFilterChip extends StatelessWidget {
  final ReportDateRange? value;
  final ValueChanged<ReportDateRange?> onChanged;

  const ReportDateRangeFilterChip({super.key, required this.value, required this.onChanged});

  /// Số năm có thể lùi lại khi chọn ngày.
  static const int _yearsBack = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final range = value;

    return ReportFilterChip(
      label: l10n.filterTimeframe,
      valueLabel: range == null ? null : format(range, Localizations.localeOf(context).toLanguageTag()),
      active: range != null,
      icon: Icons.calendar_today_outlined,
      onTap: () => _openOptions(context),
    );
  }

  /// "12/3/2026" cho một ngày; "1/3 – 15/3/2026" trong cùng năm; đủ năm ở 2 đầu nếu khác năm.
  static String format(ReportDateRange range, String locale) {
    final full = DateFormat.yMd(locale);
    if (range.isSingleDay) return full.format(range.start);
    final startFormat = range.start.year == range.end.year ? DateFormat.Md(locale) : full;
    return '${startFormat.format(range.start)} – ${full.format(range.end)}';
  }

  void _openOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final range = value;
    showReportFilterSheet<_DateMode?>(
      context: context,
      title: l10n.filterTimeframe,
      options: [
        ReportFilterOption(value: null, label: l10n.timeframeAll),
        ReportFilterOption(value: _DateMode.singleDay, label: l10n.pickSingleDate, icon: Icons.event_outlined),
        ReportFilterOption(value: _DateMode.range, label: l10n.pickDateRange, icon: Icons.date_range_outlined),
      ],
      selected: range == null ? null : (range.isSingleDay ? _DateMode.singleDay : _DateMode.range),
      onSelected: (mode) => _apply(context, mode),
    );
  }

  Future<void> _apply(BuildContext context, _DateMode? mode) async {
    if (mode == null) {
      onChanged(null);
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = DateTime(today.year - _yearsBack, 1, 1);
    final current = value;

    switch (mode) {
      case _DateMode.singleDay:
        final picked = await showDatePicker(
          context: context,
          initialDate: _clamp(current?.start ?? today, firstDate, today),
          firstDate: firstDate,
          lastDate: today,
        );
        if (picked != null) onChanged(ReportDateRange(start: picked, end: picked));
      case _DateMode.range:
        final picked = await showDateRangePicker(
          context: context,
          initialDateRange: current == null || current.isSingleDay
              ? null
              : DateTimeRange(start: _clamp(current.start, firstDate, today), end: _clamp(current.end, firstDate, today)),
          firstDate: firstDate,
          lastDate: today,
        );
        if (picked != null) onChanged(ReportDateRange(start: picked.start, end: picked.end));
    }
  }

  static DateTime _clamp(DateTime date, DateTime min, DateTime max) =>
      date.isBefore(min) ? min : (date.isAfter(max) ? max : date);
}
