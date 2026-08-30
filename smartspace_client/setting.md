# Yêu cầu thiết kế UI/UX: Màn hình Quản lý thiết bị (Manage Devices / Active Sessions)

**Nền tảng:** Mobile App (Môi trường Flutter)
**Chủ đề (Theme):** Sáng (Light mode), hiện đại, tối giản, các thành phần được phân chia rõ ràng bằng đường viền mỏng hoặc nền dạng thẻ (card) bo góc nhẹ.

## 1. Phần Header (App Bar)

- **Nút Back (Quay lại):** Nằm ở góc trên bên trái.
- **Tiêu đề trang:** "Quản lý thiết bị" (Căn giữa hoặc căn trái, chữ đậm, rõ nét).

## 2. Phần Body (Danh sách Thiết bị đang đăng nhập)

Hiển thị một danh sách (ListView) các thiết bị có phiên đăng nhập hợp lệ. Phía trên cùng có tiêu đề nhóm: **"Thiết bị đã đăng nhập"** (in đậm).

### 2.1. Thiết bị hiện tại (This Device)

Cần được làm nổi bật để người dùng nhận biết đây là thiết bị họ đang cầm trên tay.

- **Header thẻ:** Có dòng chữ nhỏ màu xanh lá "Thiết bị này" và icon checkmark (✓) màu xanh lá ở góc phải.
- **Icon thiết bị:** Biểu tượng điện thoại di động (📱) nằm bên trái.
- **Thông tin chi tiết (nằm giữa):**
  - Tên thiết bị: VD "iPhone 15 Pro Max" (Chữ màu đen, in đậm).
  - Vị trí: VD "Hồ Chí Minh, Việt Nam" (Chữ màu xám, kích thước nhỏ hơn).
  - Trạng thái: Một chấm tròn nhỏ màu xanh lá cây + text "Đang hoạt động" (Active now).
- **Action:** KHÔNG có nút đăng xuất ở thiết bị này.

### 2.2. Các thiết bị khác (Other Devices)

Nằm dưới thiết bị hiện tại, ngăn cách bằng đường viền mỏng (divider).

- **Icon thiết bị:** Biểu tượng máy tính (💻) cho trình duyệt web hoặc điện thoại cho mobile app.
- **Thông tin chi tiết (nằm giữa):**
  - Tên thiết bị/Trình duyệt: VD "Chrome trên Windows 11" (Chữ màu đen, in đậm).
  - Vị trí: VD "Hà Nội, Việt Nam" (Chữ màu xám).
  - Thời gian: VD "Hoạt động lần cuối lúc 10:30 AM" (Chữ màu xám).
- **Action (Nút Đăng xuất đơn lẻ):** Nằm ở cạnh phải của mỗi dòng thiết bị. Nút nhỏ, viền màu đỏ, chữ màu đỏ "Đăng xuất" (Outline button).
