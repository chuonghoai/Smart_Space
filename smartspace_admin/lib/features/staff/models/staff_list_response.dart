import 'package:smartspace_admin/features/staff/models/staff_model.dart';
import 'package:smartspace_admin/features/staff/models/staff_summary_model.dart';

class StaffListResponse {
  final StaffSummaryModel summary;
  final List<StaffModel> staffs;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final int totalElements;

  const StaffListResponse({
    required this.summary,
    required this.staffs,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
  });

  factory StaffListResponse.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};
    final staffsJson = json['staffs'] as Map<String, dynamic>? ?? {};
    final contentList = staffsJson['content'] as List<dynamic>? ?? [];

    return StaffListResponse(
      summary: StaffSummaryModel.fromJson(summaryJson),
      staffs: contentList
          .map((e) => StaffModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (staffsJson['currentPage'] as num?)?.toInt() ?? 1,
      pageSize: (staffsJson['pageSize'] as num?)?.toInt() ?? 10,
      totalPages: (staffsJson['totalPages'] as num?)?.toInt() ?? 1,
      totalElements: (staffsJson['totalElements'] as num?)?.toInt() ?? 0,
    );
  }
}
