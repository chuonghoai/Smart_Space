# SmartSpace Backlog — Phân công Phản ánh Tự động (Auto-Assign Report)

> Lộ trình 4 giai đoạn triển khai tính năng **Phân công phản ánh tự động hỗ trợ phân công thủ công** cho toàn bộ hệ thống (`SmartSpace_Backend`, `smartspace_client`, `smartspace_admin`, `smartspace_staff`).

---

## Giai đoạn 1 — Nền tảng Dữ liệu: Danh mục phản ánh & Tọa độ đại diện nhân viên

**Mục tiêu:** Chuẩn bị đầy đủ dữ liệu đầu vào (`ReportCategory` ánh xạ nhiều-nhiều với `Position` và tọa độ đại diện của nhân viên) mà không làm gián đoạn luồng vận hành hiện có.

### Backend (`SmartSpace_Backend`)
- [x] Mở rộng `User` với `baseLatitude`, `baseLongitude`, `baseAddress` (tọa độ đại diện / trạm phụ trách của nhân viên)
- [x] Cập nhật `CreateStaffRequest`, `UpdateStaffRequest`, `StaffResponse`, `StaffServiceImpl` (validate cặp tọa độ, giới hạn `-90..90` / `-180..180`, hỗ trợ `clearBaseLocation`)
- [x] Tạo entity `ReportCategory` + bảng trung gian `report_category_positions` (nhiều-nhiều với `Position`) + liên kết nullable `category_id` trong `Report`
- [x] Tạo `ReportCategoryRepository`, `IReportCategoryService` / `ReportCategoryServiceImpl`, `CategoryController` (`GET /categories`), `AdminCategoryController` (`/admin/categories`)
- [x] Cập nhật `ReportCreateRequest`, `ReportDetailResponse`, `ReportResponse`, `RecentReportResponse`, `ReportServiceImpl` để lưu và trả về danh mục phản ánh (tương thích ngược report cũ `category_id = null`)
- [x] Seed 5 danh mục mặc định trong `DataInitializer` khi bảng `report_categories` trống và bổ sung key i18n `messages_vi.properties` / `messages_en.properties`

### Client (`smartspace_client`)
- [x] Tạo `ReportCategoryModel`, bổ sung `getCategories()` vào `ReportRepo` / `ReportRepoApi` / `ReportRepoMock` / `ReportService` và `reportCategoriesProvider`
- [x] Cập nhật `CreateReportScreen` & `CreateReportController` cho phép người dân chọn **Danh mục phản ánh** khi tạo/sửa phản ánh (`category_id`)
- [x] Hiển thị badge danh mục trên `ReportDetailScreen` + bổ sung L10n song ngữ VI/EN

### Admin (`smartspace_admin`)
- [x] Tạo feature `category` (`CategoryModel`, `CategoryRepository`, `category_providers.dart`) + màn `CategoryManagementScreen` quản lý danh mục & gán nhiều chức vụ (`Position`)
- [x] Đăng ký route chuẩn 3 file (`route_name.dart`, `router_path.dart`, `app_router.dart`) + bổ sung vào `sidebar.dart` (Web & Mobile)
- [x] Nâng cấp form Tạo/Sửa nhân viên (`StaffForm`) hỗ trợ nhập địa chỉ/tọa độ đại diện và chọn trực tiếp trên bản đồ (`StaffLocationPickerDialog`)
- [x] Hiển thị tọa độ đại diện trong danh sách/chi tiết nhân viên và badge danh mục trong `AdminReportDetailScreen` + L10n VI/EN

---

## Giai đoạn 2 — Lõi Thuật toán Phân công Tự động & Gợi ý Thông minh

**Mục tiêu:** Đưa bộ não chấm điểm đa tiêu chí vào vận hành thực tế theo 3 chế độ (`AUTO` / `ASSIST` / `MANUAL`), có giải trình và thông báo realtime đa ngôn ngữ.

- [x] **Backend (`SmartSpace_Backend`)**
  - [x] Tạo entity `AutoAssignConfig`, `AssignmentDecisionLog` và các enum `EAutoAssignMode`, `EAssignmentSource`, `EAssignmentOutcome`
  - [x] Tách `GeoUtils` (Haversine & kiểm tra tọa độ) dùng chung cho toàn backend
  - [x] Xây dựng `AutoAssignServiceImpl`:
    - [x] **Vòng 1 — Lọc cứng:** tài khoản `active`, `role = staff`, chức vụ thuộc `category.positions`, đã có tọa độ đại diện, `activeProcessingCount < maxConcurrentTasks`, khoảng cách `<= maxRadiusKm`
    - [x] **Vòng 2 — Chấm điểm đa tiêu chí (0–100):** chuẩn hóa **Khoảng cách (45%) + Khối lượng tháng (35%) + Tải đang xử lý (15%) + Hiệu suất đúng hạn 30 ngày (5%)** bằng batch `GROUP BY` queries (tránh N+1) + tie-breaker xác định
  - [x] Khóa phân công tuần tự bằng khóa hàng DB trên cấu hình (`SELECT ... FOR UPDATE`), giữ tới khi commit — bao trọn cả bước chấm điểm lẫn bước lưu người được giao, an toàn khi chạy nhiều instance (thay cho khóa Redis ban đầu vốn nhả khóa trước khi lưu)
  - [x] Phân công chạy **sau khi phản ánh đã commit**, trong transaction riêng: lỗi của bộ máy phân công không làm hỏng việc tạo phản ánh của người dân
  - [x] Tách core `executeAssign(...)` từ `ReportServiceImpl.assignReport` để tái sử dụng 100% giữa Manual & Auto (tạo Chat, tính Deadline, ghi `ActivityHistory`, đẩy WebSocket + FCM theo `User.getLanguage()` + `MessageSource`)
  - [x] Fallback an toàn giữ `pending` kèm `fallbackReason` khi không có ứng viên đạt chuẩn; đánh dấu `OVERRIDDEN` khi Admin đổi người phụ trách (cả với quyết định máy giao lẫn máy đề xuất)
  - [x] Chế độ mặc định **`ASSIST`** (máy chỉ đề xuất) cho tới khi có màn cấu hình ở Giai đoạn 3
  - [x] Phiếu giải trình (chứa liên hệ, tọa độ, điểm của ứng viên) **chỉ trả cho Admin**; feed công khai, người dân và nhân viên không nhận
- [x] **Admin (`smartspace_admin`)**
  - [x] Nâng cấp `AdminReportDetailScreen` & `MapQuickAssignSheet`: hiển thị **Top 3 nhân viên đề xuất** kèm phân rã điểm (khoảng cách, tải tháng, đang xử lý) + nút **1 chạm "Giao ngay"** / **"Phân công tự động"**
  - [x] Hiển thị **Phiếu giải trình phân công tự động** trên chi tiết phản ánh khi report được máy giao
  - [x] **Giao lại nhân viên** cho phản ánh đang xử lý (bottom sheet chọn nhân viên khác)

---

## Giai đoạn 3 — Điểm nhấn Flagship: Trung tâm Điều phối Thông minh & Bản đồ

**Mục tiêu:** Biến thuật toán chạy ngầm thành trải nghiệm điều hành trực quan, chứng minh rõ tính thông minh và công bằng.

- [x] **Backend (`SmartSpace_Backend`)**
  - [x] API cấu hình (`GET/PUT /admin/auto-assign/config`)
  - [x] API mô phỏng không ghi DB (`POST /admin/auto-assign/simulate`)
  - [x] API thống kê hiệu quả, độ công bằng tải tháng & nhật ký quyết định (`GET /admin/auto-assign/analytics`, `/logs`)
- [x] **Admin (`smartspace_admin`)**
  - [x] Xây dựng màn `AutoAssignCenterScreen` (chuẩn 3 file route + `DESIGN.md` + `app-screens.md`):
    - [x] Chuyển đổi chế độ `AUTO` / `ASSIST` / `MANUAL` và thanh trượt chỉnh trọng số (tự khóa tổng 100%), bán kính, ngưỡng tải
    - [x] **Bộ mô phỏng Dry-Run Simulator:** chọn danh mục + chấm điểm sự cố trên bản đồ → xem ngay bảng xếp hạng ứng viên thay đổi theo trọng số
    - [x] KPI Công bằng tải tháng, tỷ lệ tự động thành công, tỷ lệ Admin giữ nguyên (Acceptance Rate) và nhật ký quyết định
  - [x] Bổ sung layer **Vị trí đại diện nhân viên** trên `AdminMapScreen` kèm trạng thái tải
- [x] **Staff (`smartspace_staff`)**
  - [x] Hiển thị tọa độ / khu vực phụ trách đại diện (chỉ xem) trong màn Hồ sơ cá nhân

---

## Giai đoạn 4 — Kiểm thử Chịu tải, Đồng thời & Hoàn thiện QA

**Mục tiêu:** Đảm bảo chất lượng, an toàn dữ liệu đồng thời, 100% song ngữ VI/EN và tương phản chuẩn cả Light Mode & Dark Mode.

- [~] Viết Unit Tests cho thuật toán chấm điểm, tie-breaker, fallback — đã có `AutoAssignServiceTest` & `ReportAutoAssignFlowTest`, còn thiếu ca biên trọng số / chuẩn hóa điểm
- [ ] Viết Concurrency Tests mô phỏng nhiều phản ánh gửi song song (`AutoAssignConcurrencyTest`)
- [ ] Viết Integration Tests API và tích hợp lệnh chạy nhanh vào `testapi.ps1`
- [ ] Audit `flutter analyze`, Light/Dark Mode contrast (WCAG AA), và 100% L10n key trên tất cả app
- [ ] Đồng bộ test case chuẩn `SMP-XXX` tại `docs/TestCases/` và `docs/TestCaseList.md`

---

## Cập nhật tiến độ — 23/11/2026: Hệ thống hiện phục vụ được gì

> Đã xong Giai đoạn 1 và Giai đoạn 2. Mục này mô tả **năng lực đang dùng được**, không liệt kê file.

### Người dân (Client)
- Chọn **danh mục phản ánh** khi tạo hoặc sửa phản ánh. Danh mục quyết định mức độ nghiêm trọng mặc định và nhóm nhân viên phụ trách.
- Vẫn sửa được phản ánh cũ dù danh mục của nó đã ngừng hoạt động. Chỉ bị chặn khi đổi sang một danh mục đã ngừng.
- Gửi phản ánh luôn thành công, kể cả khi bộ máy phân công gặp lỗi. Khi được giao, người dân nhận thông báo và tin nhắn chat hệ thống bằng ngôn ngữ của mình.
- Không nhìn thấy thông tin nội bộ về việc chấm điểm nhân viên.

### Admin
- **Quản lý danh mục:** tạo, sửa, ngừng, xóa danh mục; gán nhiều chức vụ phụ trách cho mỗi danh mục.
- **Tọa độ trạm của nhân viên:** nhập địa chỉ/tọa độ hoặc chọn trên bản đồ khi tạo/sửa nhân viên.
- **Gợi ý thông minh (chế độ mặc định ASSIST):** mỗi phản ánh đang chờ hiển thị **Top 3 nhân viên phù hợp nhất**, kèm điểm 0–100 và phân rã theo khoảng cách, khối lượng tháng, tải đang xử lý, tỷ lệ đúng hạn 30 ngày. Nếu không có ai đạt chuẩn, hệ thống nêu rõ lý do (thiếu danh mục, chưa gán chức vụ, ngoài bán kính, quá tải…).
- **3 cách phân công:**
  - "Giao ngay" một nhân viên trong danh sách đề xuất.
  - "Phân công tự động" để máy chọn người tốt nhất (chỉ áp dụng cho phản ánh đang chờ).
  - Chọn thủ công như trước.
- **Giao lại** cho nhân viên khác khi phản ánh đang xử lý.
- **Phiếu giải trình** trên chi tiết phản ánh: ai được chọn, điểm bao nhiêu, bảng xếp hạng ứng viên tại thời điểm quyết định, và Admin có ghi đè đề xuất của máy hay không.
- Nhật ký hoạt động ghi rõ lượt nào do hệ thống tự giao, lượt nào do Admin giao, hiển thị đúng ngôn ngữ của người xem.

### Nhân viên (Staff)
- Nhận việc từ cả 3 cách phân công, kèm thông báo đẩy. Lượt máy tự giao có tiêu đề riêng.
- Nhờ đồng nghiệp làm giùm vẫn hoạt động như cũ; lượt chuyển giao được ghi nhận là nguồn phân công "nhờ làm giùm".

### Bộ máy phân công
- **Lọc cứng:** đúng chức vụ của danh mục, tài khoản đang hoạt động, đã có tọa độ trạm, chưa vượt số việc đồng thời (mặc định 10), trong bán kính (mặc định 15 km).
- **Chấm điểm:** khoảng cách 45% · khối lượng tháng 35% · tải đang xử lý 15% · đúng hạn 30 ngày 5%. Khi bằng điểm, hệ thống chọn theo thứ tự cố định: ít việc hơn, gần hơn, lâu chưa được giao hơn.
- **An toàn đồng thời:** nhiều phản ánh tạo cùng lúc được xử lý lần lượt, nên không giao trùng một người vượt ngưỡng tải, kể cả khi chạy nhiều server.
- **Chế độ AUTO** (máy tự giao ngay khi có phản ánh) đã sẵn sàng. Hiện chỉ bật được bằng cách sửa cấu hình trong DB. Ở chế độ này, Admin được báo khi máy không giao được.

### Lưu ý vận hành
- DB đã từng chạy bản cũ sẽ còn cấu hình `AUTO`. Muốn dùng mặc định mới thì đổi `auto_assign_configs.mode` sang `ASSIST`.
- Chưa có màn cấu hình chế độ, trọng số, bán kính (Giai đoạn 3).
- Integration test qua API cần chạy backend bằng code hiện tại trước khi chạy lại.
