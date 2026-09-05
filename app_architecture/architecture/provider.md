# Provider Layer

Đây là layer quan trọng nhất trong việc quản lý trạng thái chia sẻ (Shared State Management) của toàn ứng dụng (như `ReportsNotifier`, `NotificationNotifier`).

## Trách nhiệm (Responsibility)
- Quản lý **Domain/Feature State** (ví dụ: danh sách report, số lượng thông báo).
- Đóng gói Business Logic phức tạp.
- Gọi các **Service** tương ứng để lấy hoặc cập nhật dữ liệu.
- Xử lý tính toán (ví dụ: tính toán khoảng cách đến các điểm báo cáo nguy hiểm).

## Quy tắc DO / DON'T

**DO:**
- Khai báo dưới dạng `StateNotifier<T>` của Riverpod.
- Khai báo `State` class bất biến (immutable) với method `copyWith`.
- Quản lý các trạng thái: `isLoading`, `error`, `data`, thời gian cập nhật.
- Inject `Service` (như `ReportService`) qua constructor hoặc biến toàn cục hợp lệ.

**DON'T:**
- KHÔNG chứa logic UI (không refer đến context, không tự navigate màn hình).
- KHÔNG gọi trực tiếp API client mà phải thông qua Service/Repository.
- KHÔNG lưu trữ state của UI thuần tuý (như "tab đang mở là số mấy") - việc đó của UI Controller.
