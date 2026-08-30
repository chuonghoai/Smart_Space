# Quy tắc Service và Repository Layer

Hai layer này đảm nhận business logic và thao tác với nguồn dữ liệu.

## Service

### Trách nhiệm của Service:
- Chứa Business/application logic.
- Điều phối nghiệp vụ chung.
- Xử lý logic nằm giữa Controller và Repository.
- Gọi Repository để lấy/gửi dữ liệu.
- Phối hợp nhiều Repository hoặc Service khác nếu nghiệp vụ yêu cầu.
- Chuẩn hóa hoặc xử lý kết quả từ Repository trước khi trả về cho Controller khi phù hợp.

### Service KHÔNG NÊN:
- Phụ thuộc trực tiếp vào UI widget.
- Quản lý UI state (như loading/error của một màn hình cụ thể).
- Thực hiện navigation giao diện.
- Chứa animation logic của UI.
- Duplicate data-fetching logic vốn thuộc về Repository.

---

## Repository

### Trách nhiệm của Repository:
- Giao tiếp trực tiếp với Data source (API, Database, Mock data, Local data source).
- Đóng gói request và parse response.

Repository tập trung vào luồng: `Controller -> Service -> Repository -> Data Source`.

### Repository KHÔNG NÊN:
- Phụ thuộc vào UI.
- Quản lý UI state.
- Thực hiện điều hướng UI (navigation).
- Chứa animation logic.
- Trực tiếp điều khiển UI.
- Chứa business/application logic vốn thuộc thẩm quyền của Service.
