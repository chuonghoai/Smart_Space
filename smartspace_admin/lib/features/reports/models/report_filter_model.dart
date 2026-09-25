import 'package:intl/intl.dart';

class ReportFilter {
  final String? status;
  final String? severity;
  final String? assigneeId;
  final DateTime? from;
  final DateTime? to;
  final String? search;
  final int page;
  final int size;

  const ReportFilter({
    this.status,
    this.severity,
    this.assigneeId,
    this.from,
    this.to,
    this.search,
    this.page = 1,
    this.size = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final fmt = DateFormat('yyyy-MM-dd');
    return {
      if (status != null && status!.isNotEmpty) 'status': status,
      if (severity != null && severity!.isNotEmpty) 'severity': severity,
      if (assigneeId != null && assigneeId!.isNotEmpty) 'assigneeId': assigneeId,
      if (from != null) 'from': fmt.format(from!),
      if (to != null) 'to': fmt.format(to!),
      if (search != null && search!.isNotEmpty) 'search': search,
      'page': page,
      'size': size,
    };
  }

  ReportFilter copyWith({
    String? status,
    String? severity,
    String? assigneeId,
    DateTime? from,
    DateTime? to,
    String? search,
    int? page,
    int? size,
    bool clearStatus = false,
    bool clearSeverity = false,
    bool clearAssignee = false,
    bool clearDates = false,
    bool clearSearch = false,
  }) {
    return ReportFilter(
      status: clearStatus ? null : (status ?? this.status),
      severity: clearSeverity ? null : (severity ?? this.severity),
      assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
      search: clearSearch ? null : (search ?? this.search),
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  bool get isActive =>
      (status != null && status!.isNotEmpty) ||
      (severity != null && severity!.isNotEmpty) ||
      (assigneeId != null && assigneeId!.isNotEmpty) ||
      from != null ||
      to != null ||
      (search != null && search!.isNotEmpty);
}
