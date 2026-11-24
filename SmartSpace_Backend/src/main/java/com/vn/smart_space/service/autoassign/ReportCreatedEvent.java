package com.vn.smart_space.service.autoassign;

/**
 * Phát ra trong transaction tạo phản ánh. Listener chỉ xử lý sau khi transaction đó commit,
 * nên lỗi của bộ máy phân công tự động không thể làm hỏng việc tạo phản ánh của người dân.
 */
public record ReportCreatedEvent(String reportId) {
}
