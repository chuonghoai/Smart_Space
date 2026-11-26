/// Khoảng ngày tạo phản ánh để lọc (tính theo ngày, cả 2 đầu đều bao gồm).
///
/// Gửi lên API dạng `from`/`to` = `yyyy-MM-dd`; backend tính từ đầu ngày [start] tới hết ngày [end].
/// Một ngày cụ thể = [start] trùng [end].
class ReportDateRange {
  final DateTime start;
  final DateTime end;

  /// Bỏ phần giờ; nếu [start] sau [end] thì đảo lại.
  factory ReportDateRange({required DateTime start, required DateTime end}) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return s.isAfter(e) ? ReportDateRange._(e, s) : ReportDateRange._(s, e);
  }

  const ReportDateRange._(this.start, this.end);

  bool get isSingleDay => start == end;

  String get fromQuery => _isoDate(start);
  String get toQuery => _isoDate(end);

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) => other is ReportDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
