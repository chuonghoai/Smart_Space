class ReportDeadlineHelper {
  const ReportDeadlineHelper._();

  /// Returns `true` if a report is overdue (active `pending`/`processing` past
  /// [deadline], or `processed` completed after [deadline]).
  /// Once a report becomes overdue—including when completed late—it stays
  /// marked overdue unless a new deadline is set (e.g. re-handling approved).
  static bool isOverdue({
    required String status,
    DateTime? deadline,
    DateTime? resolvedAt,
    bool? serverIsOverdue,
    DateTime? now,
  }) {
    final normalized = status.toLowerCase();
    if (normalized == 'rejected') return false;
    if (serverIsOverdue == true) return true;
    if (deadline == null) return false;
    if (normalized == 'processed' || normalized == 'resolved') {
      return resolvedAt != null && resolvedAt.isAfter(deadline);
    }
    if (normalized == 'pending' || normalized == 'processing') {
      final eval = now ?? DateTime.now();
      return !deadline.isAfter(eval);
    }
    return false;
  }

  /// Returns `>= 1` remaining days while the report is still `pending` or
  /// `processing` and within [deadline]; returns `null` when overdue, completed,
  /// rejected, or when [deadline] is absent.
  static int? remainingDays({
    required String status,
    DateTime? deadline,
    DateTime? resolvedAt,
    bool? serverIsOverdue,
    int? serverRemainingDays,
    DateTime? now,
  }) {
    if (isOverdue(
      status: status,
      deadline: deadline,
      resolvedAt: resolvedAt,
      serverIsOverdue: serverIsOverdue,
      now: now,
    )) {
      return null;
    }
    final normalized = status.toLowerCase();
    if (normalized == 'rejected' ||
        normalized == 'processed' ||
        normalized == 'resolved' ||
        deadline == null) {
      return null;
    }
    if (serverRemainingDays != null && serverRemainingDays > 0) {
      return serverRemainingDays;
    }
    final eval = now ?? DateTime.now();
    if (!deadline.isAfter(eval)) return null;
    final seconds = deadline.difference(eval).inSeconds;
    if (seconds <= 0) return null;
    final days = (seconds / 86400).ceil();
    return days < 1 ? 1 : days;
  }
}
