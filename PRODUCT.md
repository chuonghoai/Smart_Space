# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack

Flutter (Dart) cho Client (`smartspace_client`), Admin (`smartspace_admin`), Staff (`smartspace_staff`) và module dùng chung (`mobile_shared`); Spring Boot (Java 17/21) Maven với WebSocket STOMP cho Backend API (`SmartSpace_Backend`).

## Users

- **Cư dân / Người dân (Client):** Sử dụng ứng dụng di động để phản ánh sự cố môi trường, hạ tầng, trật tự công cộng; theo dõi tiến độ xử lý và nhận cảnh báo khi di chuyển gần khu vực có sự cố (Geofencing cảnh báo định kỳ).
- **Cán bộ / Nhân viên xử lý (Staff):** Sử dụng ứng dụng di động tiếp nhận phản ánh được điều phối, xem vị trí/lộ trình và cập nhật tiến độ, kết quả xử lý hiện trường.
- **Ban quản trị / Điều hành (Admin):** Sử dụng giao diện Web/Desktop để giám sát tổng thể bản đồ số sự cố, điều phối và phân công nhân viên, quản lý danh mục và xem báo cáo thống kê.

## Product Purpose

Xây dựng nền tảng thông minh cho phép tiếp nhận, điều phối, xử lý và giám sát thời gian thực (Realtime WebSocket) các vấn đề môi trường, cơ sở hạ tầng và an toàn công cộng dựa trên định vị không gian (GIS/Bản đồ số), nâng cao tính kết nối cộng đồng và hiệu quả xử lý đô thị.

## Positioning

Nền tảng phản ánh đô thị thông minh tương tác thời gian thực hai chiều: tích hợp bản đồ số gom cụm vị trí thông minh, cơ chế cảnh báo chủ động dựa trên vị trí di chuyển thực tế của người dùng và đồng bộ trạng thái ngay lập tức qua WebSocket giữa các phân hệ Client, Admin và Staff.

## Operating Context

- **Hiện trường di động (Client & Staff):** Người dân thao tác ngoài trời cần chụp ảnh, chọn vị trí và gửi phản ánh nhanh chóng; cán bộ hiện trường thao tác cập nhật trạng thái tiện lợi khi đang di chuyển.
- **Trung tâm điều hành (Admin):** Màn hình lớn với dữ liệu bản đồ số dày đặc, phân cụm sự cố phức tạp và nhiều chỉ số thống kê.
- **Môi trường ánh sáng đa dạng:** Bắt buộc hỗ trợ tối ưu cả Dark Mode và Light Mode đạt độ tương phản chuẩn WCAG AA.

## Capabilities and Constraints

- **Capabilities:**
  - Định vị GPS và hiển thị bản đồ trực quan với cơ chế gom cụm (clustering) và mở danh sách vị trí khi nhiều điểm phản ánh nằm sát nhau.
  - Tạo phản ánh đa phương tiện (hình ảnh, mô tả, phân loại).
  - Tự động cập nhật tọa độ và phát cảnh báo khi người dùng đến gần khu vực có sự cố.
  - Đồng bộ sự kiện và trạng thái tức thì qua WebSocket STOMP và Push Notification.
- **Constraints:**
  - Tuân thủ nghiêm ngặt quy tắc L10n (`.agents/rules/shared-ui-l10n-rules.md`), hỗ trợ đầy đủ Tiếng Việt và Tiếng Anh, tuyệt đối không hardcode text hiển thị.
  - Tuân thủ quy tắc kiến trúc phân lớp Controller - Service - Repository - Model, GoRouter, Provider/State Management theo `app_architecture/`.
  - Tuân thủ quy tắc chống lỗi khuôn mẫu AI (Anti-slop) theo `design-taste-frontend`.

## Brand Commitments

- **Màu sắc chủ đạo:** Teal (`#00796B`) kết hợp Green (`#558B2F`), tượng trưng cho công nghệ, sự tin cậy và ý thức sinh thái / môi trường xanh.
- **Nguyên tắc nhận diện (Voice & Tone):** Đáng tin cậy (Trust), Rõ ràng (Clarity), Điềm tĩnh (Calm), Hướng tới hành động (Action-oriented), Gần gũi với cộng đồng (Community-minded).
- **Tránh thói quen mặc định:** Không dùng gradient tím xanh AI-slop, không lạm dụng bóng đổ quá đà, tránh dùng đường kẻ hairline ngăn cách khi có thể phân tách bằng khoảng cách và sắc độ.

## Evidence on Hand

- Hệ thống Design System hoàn chỉnh tại `app_architecture/design/design.md`.
- Báo cáo tiến độ và tài liệu nghiệp vụ tại `weekly_reports/`.
- Codebase Flutter đã triển khai các màn hình chuẩn tại `smartspace_client`, `smartspace_admin`, `smartspace_staff`, `mobile_shared`.

## Product Principles

1. **Hành động nhanh, tối thiểu rào cản:** Quy trình tạo phản ánh sự cố phải trực quan, dễ thao tác trong điều kiện thực tế ngoài trời.
2. **Minh bạch và Thời gian thực:** Tiến độ tiếp nhận và giải quyết phản ánh được cập nhật tức thì đến mọi bên liên quan.
3. **Tiếp cận toàn diện:** Đảm bảo độ tương phản cao, kích thước vùng chạm tối thiểu 48x48 dp, hỗ trợ song ngữ hoàn chỉnh.
4. **Bản đồ là trung tâm:** Trải nghiệm định vị và hiển thị cụm điểm phản ánh phải mượt mà và chính xác.

## Accessibility & Inclusion

- Độ tương phản đạt chuẩn WCAG AA ở cả Light Mode và Dark Mode.
- Touch target kích thước chuẩn cho thiết bị di động.
- Bản địa hóa (L10n) 100% text người dùng nhìn thấy (Tiếng Việt & Tiếng Anh).

