# Yêu cầu thiết kế UI/UX: Màn hình Chỉnh sửa hồ sơ (Edit Profile)

**Nền tảng:** Mobile App (Flutter)
**Chủ đề (Theme):** Sáng (Light mode), tối giản, giao diện dạng thẻ (card) và các trường nhập liệu bo góc mềm mại.
**Màu sắc chủ đạo:** Trắng (Nền), Xám nhạt (Nền input/thẻ), Đen (Văn bản chính), Đỏ (Nút bấm action).

## 1. Phần Header (App Bar)

- **Nút Back (Quay lại):** Nằm ở góc trên bên trái.
- **Tiêu đề trang:** "Quản lý thiết bị" (Căn giữa hoặc căn trái, chữ đậm, rõ nét).
- **Đường viền/Shadow:** App bar không viền, đồng màu với nền trang để tạo cảm giác liền mạch.

## 2. Khối Ảnh đại diện (Avatar Section)

Nằm ngay dưới App bar, được bọc trong một thẻ (Card) nền trắng, đổ bóng (shadow) mờ xung quanh, các góc bo tròn lớn.

- **Avatar:** Nằm chính giữa thẻ, hình tròn lớn (khoảng 80-100px). Có một icon Camera nhỏ bọc trong hình tròn màu đậm nằm đè lên ở góc dưới bên phải của avatar.

## 3. Khối Form Nhập liệu (Form Fields)

Các trường nhập liệu (TextField) đều có chung style: Label nằm ngoài bên trên, ô nhập liệu nền xám nhạt, bo góc bo tròn (rounded rectangle), không có viền đen dày (chỉ viền mờ). Khoảng cách giữa các trường đều nhau.

- **Trường 1: Họ và tên**
  - Label: "Họ và tên" (In đậm).
  - Textfield: Hiển thị tên hiện tại, không có icon.
- **Trường 2: Email**
  - Label: "Email" (In đậm).
  - Textfield: Hiển thị email. Có icon Ổ khóa (Lock) ở bên phải để biểu thị đây là trường chỉ đọc (Read-only), không cho phép sửa.
- **Trường 3: Ngày sinh**
  - Label: "Ngày sinh" (In đậm).
  - Textfield: Hiển thị ngày sinh (VD: 1990-01-01). Có icon Lịch (Calendar) ở bên phải để mở DatePicker khi bấm vào.
- **Trường 4: Giới tính (Segmented Control / Toggle)**
  - Label: "Giới tính" (In đậm).
  - Control: Một thanh ngang bo góc chứa 3 tùy chọn: "Nam", "Nữ", "Khác".
  - Trạng thái Active (đang chọn): Nền trắng, có shadow nổi lên (VD: "Nam"). Các mục còn lại nền xám chìm.
- **Trường 5: Số điện thoại**
  - Label: "Số điện thoại" (In đậm).
  - Textfield: Hiển thị số điện thoại (VD: +84 0123 456 789). Có icon Điện thoại (Phone) ở bên phải. Bàn phím số (keyboardType: number).

## 4. Khối Nút bấm (Footer Actions)

Nằm cố định ở dưới cùng của màn hình, gồm 2 nút bấm to, trải dài toàn màn hình (có padding 2 bên), thiết kế bo tròn hoàn toàn (Capsule/Stadium border).

- **Nút 1 (Trên): "Hủy" (Cancel)**
  - Nút dạng OutlinedButton. Nền trắng, in đậm.
- **Nút 2 (Dưới): "Lưu Thay Đổi" (Save)**
  - Nút dạng ElevatedButton. Nền đỏ đậm, không viền, chữ màu trắng, in đậm.
