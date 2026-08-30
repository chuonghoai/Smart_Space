# Yêu cầu thiết kế UI/UX: Màn hình Đổi mật khẩu (Change Password)

**Nền tảng:** Mobile App (iOS / Android)
**Chủ đề (Theme):** Sáng (Light mode), tối giản, phông nền trắng, phần header có hoa văn mờ.

## 1. Phần Header (Tiêu đề và Điều hướng)

- **Background Header:** Có một dải hoa văn (pattern) mờ dạng sóng cong ở phía trên cùng, tông màu vàng/cam nhạt, gradient nhạt dần xuống dưới.
- **Nút Back (Quay lại):** Nằm ở góc trên bên trái, icon mũi tên hướng sang trái, màu đen.
- **Tiêu đề trang:** "Đổi mật khẩu" (Căn trái, ngay dưới nút Back, chữ to, in đậm, màu đen).

## 2. Phần Body (Form nhập liệu)

Bao gồm 3 ô nhập liệu (Input field). Mỗi ô nhập liệu bao gồm:

- **Label (Tiêu đề ô):** Căn trái, chữ màu đen, in đậm nhẹ. Theo sau là **dấu sao màu đỏ (\*)** biểu thị trường bắt buộc.
- **Input Box (Ô nhập liệu):**
  - Viền (Border) màu xám nhạt, bo góc nhẹ (rounded corners).
  - Text placeholder (Văn bản gợi ý): "Nhập thông tin", màu xám nhạt.
  - Icon bên phải (Right Icon): Icon con mắt bị gạch chéo (ẩn mật khẩu), màu xám.

### Chi tiết các ô nhập liệu:

1. **Ô 1:**
   - Label: `Mật khẩu hiện tại *`
2. **Ô 2:**
   - Label: `Mật khẩu mới *`
3. **Ô 3:**
   - Label: `Nhập lại mật khẩu mới *`

## 3. Phần Hướng dẫn/Yêu cầu mật khẩu

Danh sách các điều kiện để tạo mật khẩu hợp lệ, nằm dưới ô nhập liệu thứ 3:

- Trình bày dạng danh sách có dấu check (dấu tích ✓) đầu dòng.
- Dấu check mảnh, màu đen.
- Text màu đen, kích thước chữ nhỏ hơn label.
- **Nội dung:**
  - ✓ Mật khẩu phải từ 8 đến 20 ký tự
  - ✓ Bao gồm số, chữ viết hoa, chữ viết thường
  - ✓ Bao gồm ít nhất một ký tự đặc biệt !@#$^()\_

## 4. Phần Footer (Nút Hành động)

- **Nút "Xác nhận" (Confirm):**
  - Nút to, bo góc, trải dài toàn màn hình (có margin 2 bên).
  - Đặt cố định (fixed) ở dưới cùng màn hình (trên thanh home indicator).
  - Màu sắc: Nền màu đỏ đậm (Red), chữ màu trắng, in đậm.
