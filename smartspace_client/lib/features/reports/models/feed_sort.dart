/// Thứ tự Bảng tin cộng đồng. Tên enum chính là giá trị `sort` của `GET /reports/feed`.
///
/// [nearby] sắp xếp theo khoảng cách ở backend (cần toạ độ người dùng), nên phân trang luôn đúng thứ tự.
enum FeedSort { latest, nearby }
