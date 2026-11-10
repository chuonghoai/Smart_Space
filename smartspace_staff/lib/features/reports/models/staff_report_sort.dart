/// Thứ tự danh sách việc được giao. Tên enum chính là giá trị `sort` của `GET /reports/staff/assigned`.
///
/// Sắp xếp ở backend nên phân trang luôn đúng thứ tự.
enum StaffReportSort { latest, oldest, severity }
