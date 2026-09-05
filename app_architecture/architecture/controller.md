# Controller Layer

Trong dự án `smartspace_client`, Controller đóng vai trò là **UI Controller** (như `HomeController`, `SettingsController`).

## Trách nhiệm (Responsibility)
- Quản lý **Local UI State** (ví dụ: cờ `isLoading`, error message tạm thời, form data chưa lưu).
- Lắng nghe (listen) các thay đổi từ **Feature Provider** để cập nhật state cục bộ nếu cần.
- Điều phối các hành động từ UI (gọi hàm `manualRefresh`, handle button click).

## Quy tắc DO / DON'T

**DO:**
- Khai báo dưới dạng `StateNotifier<T>` của Riverpod.
- Truyền `Ref` vào constructor để có thể read/listen các Provider khác.
- Lắng nghe Provider bằng `ref.listen`.
- Xử lý các logic thuần tuý của UI (ví dụ: check điều kiện trước khi gọi Provider).

**DON'T:**
- KHÔNG gọi API trực tiếp (`apiClient.get()`).
- KHÔNG chứa business logic phức tạp của hệ thống (phải đẩy xuống Feature Provider hoặc Service).
- KHÔNG lưu trữ dữ liệu domain lâu dài (đó là việc của Feature Provider).
