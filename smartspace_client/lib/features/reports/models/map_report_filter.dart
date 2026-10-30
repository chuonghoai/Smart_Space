/// Bộ lọc report trên bản đồ Client. Tên enum chính là giá trị `filter` của `GET /reports/map`.
///
/// Report đã xử lý chỉ hiện với chính chủ (backend lọc), nên [processed] = "đã xử lý của tôi"
/// và [all] gồm report đang chờ/đang xử lý của mọi người + report đã xử lý của tôi.
enum MapReportFilter { all, mine, pending, processing, processed }
