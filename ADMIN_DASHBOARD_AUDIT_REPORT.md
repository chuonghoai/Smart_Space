# BÁO CÁO RÀ SOÁT & ĐỀ XUẤT HỆ THỐNG DASHBOARD QUẢN TRỊ — SMARTSPACE ADMIN

> **Phạm vi:** Khảo sát toàn diện mã nguồn **SmartSpace Admin** (`smartspace_admin/`), module dùng chung (`mobile_shared/`) và **Backend** (`SmartSpace_Backend/`).
> **Trạng thái tài liệu:** Báo cáo khảo sát & đề xuất kiến trúc phân tích (không thay đổi UI, API, database hay nghiệp vụ).
> **Lưu ý:** Mọi nhận định về màn hình, API, entity và trường dữ liệu đều được đối chiếu trực tiếp từ source code hiện tại của dự án.

---

## I. Tổng quan hiện trạng

### 1.1. Quy mô màn hình & điều hướng đã khảo sát

Theo `smartspace_admin/lib/routes/app_router.dart` và `smartspace_admin/lib/ui/components/sidebar.dart`, ứng dụng SmartSpace Admin hiện có **26 route trên GoRouter** (tương ứng **25 màn hình chính** — `AdminCreateEditNewsScreen` dùng chung cho `/news/create` và `/news/edit/:id`, cùng với 1 route khai báo trong `RouterPath.completeProfile` nhưng chưa gắn `GoRoute` trong `app_router.dart`). Ngoài ra có **15 màn hình/luồng nghiệp vụ quản trị cốt lõi** (cùng các dialog/bottom sheet chi tiết đi kèm) và **11 màn hình phụ trợ** (xác thực, trò chuyện chi tiết, thông báo, tìm kiếm điều hướng, cài đặt cá nhân).

#### Danh sách toàn bộ màn hình hiện có trong `smartspace_admin`

| Nhóm chức năng | Màn hình / Class | Route Path | Nền tảng / Responsive | Hiện trạng thống kê / biểu đồ |
|---|---|---|---|---|
| **Tổng quan & Giám sát** | `AdminHomeScreen` | `/home` | Adaptive (Desktop Bento 2 cột / Mobile cuộn dọc) | Banner cảnh báo phản ánh chưa thỏa đáng; 7 KPI Cards (`StatCardGrid`); Slider phản ánh mới trong 1 giờ (`NewReportsSlider`); danh sách phản ánh gần đây (4 tab); tin tức mới; lịch sử hoạt động (6 mục) |
| | `AdminAllActivitiesScreen` | `/activities` | Chung (Desktop & Mobile) | Danh sách phân trang lịch sử hoạt động + lọc theo Vai trò (`all`/`admin`/`staff`) & Chủ đề (`news`, `report_create`, `report_assign`, `report_process`); **chưa có thống kê tổng hợp** |
| **Quản lý Phản ánh** | `ReportDashboardScreen` | `/report-dashboard` | Adaptive (Table/Kanban trên Web; Card trên Mobile) | 7 KPI Cards lọc nhanh (`ReportStatCards`); 1 biểu đồ đường `ReportTrendChart` (daily/weekly/monthly); 1 biểu đồ tròn `ReportSeverityChart`; danh sách lọc & tìm kiếm |
| | `ReportListScreen` | `/report-list` | Adaptive (Table/Kanban/Card) | **Trùng phần danh sách** với `ReportDashboardScreen`, không có sidebar link trực tiếp (chỉ tìm thấy qua `/search`), không có biểu đồ |
| | `UnsatisfactoryReportsScreen` | `/reports/unsatisfactory` | Chung (2 tab: `pending` chờ giao lại, `processing` đang làm lại) | Hiển thị badge đếm số lượng trên 2 tab; **chưa có phân tích nguyên nhân/nhân viên bị đánh giá lại nhiều** |
| | `AdminReportDetailScreen` | `/reports/:id` | Adaptive (Desktop 2 cột / Mobile 1 cột) | Chi tiết sự cố, phân công nhân viên & gán mức độ, từ chối kèm lý do, mở lại xử lý lại (`reopen`), xem kết quả xử lý & đánh giá người dân |
| **Bản đồ Không gian** | `AdminMapScreen` | `/space-map` | Platform-specific (`admin_map_screen_web.dart` Mapbox GL JS iframe; `admin_map_screen_mobile.dart` Mapbox SDK) | Gom cụm marker (`cluster`) + lớp mật độ lục giác **Uber H3 Resolution 11** (`ReportDensity`) theo 6 khung thời gian (`all`, `1m`, `3m`, `6m`, `9m`, `12m`); **chưa có bảng xếp hạng điểm nóng hay số liệu tóm tắt không gian** |
| **Quản lý Nhân viên** | `StaffManagementScreen` (`WebStaffView` / `MobileStaffView`) | `/staff-management` | Adaptive (bảng trên Web; danh sách + block thống kê thu gọn trên Mobile) | Chọn tháng thống kê (`StaffStatsMonthSelector`); 4 KPI Cards (`StaffKpiGrid`); biểu đồ 2 đường `StaffFlowChart` (được giao vs đã xử lý); top 5 khối lượng `StaffWorkloadChart`; thẻ hiệu suất deadline `StaffDeadlinePerformanceCard`; chi tiết nhân viên có card workload tháng |
| **Quản lý Chức vụ** | `PositionManagementScreen` | `/position-management` | Adaptive (`PositionWebView` / Mobile list) | Web có 3 KPI Cards (Tổng chức vụ, Đang hoạt động, Nhân viên đã gán) + bảng; Mobile chỉ có danh sách |
| **Quản lý Người dùng** | `UserManagementScreen` (`WebUserView` / `MobileUserView`) | `/user-management` | Adaptive (bảng trên Web; infinite list + thống kê thu gọn trên Mobile) | 4 KPI Cards (`UserKpiGrid`); biểu đồ xu hướng đăng ký `UserRegistrationTrendChart`; top 5 người đóng góp `TopContributorsChart`; Dialog/Sheet chi tiết có thống kê 4 trạng thái phản ánh công khai của user |
| **Hội đồng Quản trị** | `AdminBoardScreen` | `/admin-board` | Adaptive (2 tab: Quản trị viên & `LockRequestsTab`) | Tab Admin có `AdminSummaryBadges` (Tổng / Hoạt động / Đã khoá); Tab Đề xuất khoá có 3 thẻ đếm (`Cần bạn`, `Đang chờ`, `Đã kết thúc`) + đồng hồ 72 giờ & phiếu bầu |
| **Quản lý Tin tức** | `AdminNewsListScreen` | `/news` | Chung (maxWidth 880 trên Desktop) | Danh sách tin tức; **chưa có thống kê** |
| | `AdminCreateEditNewsScreen` | `/news/create`, `/news/edit/:id` | Chung | Form Markdown soạn/sửa tin tức + tùy chọn gửi thông báo theo role |
| | `AdminNewsDetailScreen` | `/news/:id` | Chung | Chi tiết tin tức, sửa, xóa |
| **Giao tiếp & Thông báo** | `AdminConversationsScreen` | `/conversations` | Adaptive (Split-pane Desktop / List Mobile) | Danh sách hội thoại, lọc theo role (`all`/`client`/`staff`/`admin`) & lọc theo chức vụ staff, badge chưa đọc |
| | `AdminChatDetailScreen` | `/chat/:id` | Chung | Nhắn tin realtime STOMP, đính kèm media/phản ánh liên kết |
| | `AdminConversationInfoScreen` | `/chat/:id/info` | Chung | Thông tin hội thoại, danh sách báo cáo liên quan |
| | `AdminNotificationScreen` | `/notifications` | Chung | Danh sách thông báo cá nhân, đánh dấu đã đọc |
| **Tìm kiếm & Tài khoản** | `AdminSearchScreen` | `/search` | Chung | Tìm kiếm **tên màn hình/route điều hướng** (`RouteName.searchableRoutes`), **không tìm kiếm dữ liệu nghiệp vụ** |
| | `MobileSettingsScreen` | `/settings` | Chung | Hồ sơ, đổi ngôn ngữ (vi/en), đổi theme (Light/Dark/System), thiết bị, mật khẩu; có 1 số mục tĩnh (`shareHistory`, `notificationSettings`, `termsOfService`, `privacyPolicy`, `userGuide`, `faq` chưa gắn handler) |
| | `AdminEditProfileScreen` | `/settings/edit-profile` | Chung | Cập nhật họ tên, SĐT, ngày sinh, giới tính, ảnh đại diện |
| | `MobileChangePasswordScreen` | `/change-password` | Chung | Đổi mật khẩu |
| | `MobileManageDevicesScreen` | `/manage-devices` | Chung | Xem và thu hồi phiên đăng nhập thiết bị (Redis `RefreshTokenSession`) |
| **Xác thực & Khởi động** | `SplashScreen`, `AdminLoginScreen`, `AdminForgotPasswordScreen` | `/splash`, `/login`, `/forgot-password` | Adaptive | Khởi tạo session, đăng nhập, quên mật khẩu OTP |

*(Ghi chú thêm trong `Sidebar`: 2 mục `instructions` và `aboutApp` hiện đang để `// TODO`.)*

---

### 1.2. Đánh giá mức độ khai thác dữ liệu hiện tại

SmartSpace Admin **không phải là một ứng dụng trắng về dashboard** — hệ thống đã xây dựng được nền tảng widget dùng chung (`KpiCard`, `ChartCard`, `TrendLineChart`, `RankedBarList`, `StatCardGrid` trong `smartspace_admin/lib/ui/shared/dashboard/`) bằng `fl_chart: ^0.70.2`, cùng **4 cụm màn hình đã có số liệu thống kê**:
1. `AdminHomeScreen` (7 KPI tổng quan hiện trạng + banner sự cố chưa thỏa đáng).
2. `ReportDashboardScreen` (7 KPI đếm theo trạng thái + 1 biểu đồ trend tạo mới + 1 donut severity).
3. `StaffManagementScreen` (Dashboard hiệu suất theo tháng khá tốt: 4 KPI có so sánh kỳ trước, flow vào/ra, top 5 workload, bảng/danh sách deadline on-time).
4. `UserManagementScreen` (4 KPI có so sánh 30 ngày trước, trend đăng ký, top 5 người đóng góp).

Tuy nhiên, **mức độ khai thác dữ liệu mới dừng ở thống kê mô tả cơ bản (descriptive counting)** và còn nhiều lỗ hổng lớn trong hỗ trợ ra quyết định:

### 1.3. Những hạn chế đáng chú ý (đối chiếu từ Source Code)

1. **Dữ liệu đã thu thập nhưng chưa được khai thác để ra quyết định:**
   - **Chất lượng xử lý & Mức độ hài lòng (`Report.rating`, `Report.reviewedAt`, `Report.isReviewResolved`)**: Hệ thống đã lưu đánh giá 1–5 sao và phản hồi chưa thỏa đáng của người dân, nhưng ngoài danh sách ở `UnsatisfactoryReportsScreen` và xem từng cái ở `AdminReportDetailScreen`, **Admin không có bất kỳ chỉ số tổng hợp nào** về điểm rating trung bình toàn hệ thống, theo tháng hay theo từng nhân viên, cũng như tỷ lệ phản ánh bị đánh giá lại (`rehandling rate`).
   - **Nghiệp vụ chuyển giao công việc (`report_delegations`)**: Bảng `ReportDelegation` lưu đầy đủ lịch sử staff nhờ đồng nghiệp làm giùm (`PENDING`, `ACCEPTED`, `DECLINED`, `CANCELLED`, `EXPIRED`, `COMPLETED`, `REVOKED`), thời gian phản hồi (`respondedAt`), thời gian hoàn tất (`completedAt`), nhưng **Admin hoàn toàn không có màn hình hay chỉ số nào theo dõi hoạt động ủy quyền nội bộ này**.
   - **Hiệu suất phân tích thời gian xử lý phản ánh tại màn hình Phản ánh (`ReportDashboardScreen`)**: `ReportStatisticsResponse` chỉ đếm tồn kho all-time theo status/severity, **thiếu hoàn toàn các chỉ số vận hành cốt lõi** như: thời gian chờ phân công (`createdAt -> assignedAt`), thời gian xử lý trung bình (`assignedAt -> resolvedAt`), tỷ lệ hoàn thành (`resolved / total`), tỷ lệ từ chối (`rejected / total`), tuổi tồn đọng (`backlog aging`), và xu hướng so sánh giữa tạo mới vs giải quyết.
   - **Dữ liệu không gian H3 & Tọa độ (`ReportDensityServiceImpl`, `latitude`, `longitude`)**: Backend đã tính toán rất bài bản các ô lục giác **Uber H3 Resolution 11** lưu trong Redis cho 6 mốc thời gian (`all`, `1m`, `3m`, `6m`, `9m`, `12m`), nhưng Frontend chỉ dùng để tô màu đa giác lên bản đồ (`DensityMapLayer`) mà **chưa trích xuất danh sách/xếp hạng các điểm nóng (hotspot cells), mật độ phản ánh chưa xử lý/quá hạn theo khu vực**, hoặc so sánh biến động điểm nóng theo thời gian.

2. **Lỗ hổng kỹ thuật & dữ liệu ảnh hưởng đến tính chính xác của Dashboard (Quan trọng):**
   - **Ghi đè dữ liệu khi xử lý lại (`ReportServiceImpl.completeReport` & `updateReportStatus`)**: Khi người dân đánh giá `isReviewResolved = false` và Admin mở lại phản ánh (`processed -> processing`), rồi nhân viên hoàn tất lại, code tại `ReportServiceImpl.java` (dòng 908–916) **ghi đè** `resolvedAt` và **reset về `null`** toàn bộ `isReviewResolved`, `rating`, `reviewNote`, `reviewImageUrls`, `reviewedAt`. Ngoài ra, `ReportDelegationServiceImpl.accept` (dòng 195) **ghi đè** `report.setAssignedAt(new Date())`. Do **không có bảng lịch sử chuyển trạng thái (`report_status_history`)**, hệ thống bị mất: (a) số lần một phản ánh bị yêu cầu làm lại, (b) thời gian xử lý thực tế của vòng đầu tiên vs các vòng sau, (c) điểm rating lịch sử trước khi xử lý lại.
   - **Bất nhất trong biểu đồ xu hướng Phản ánh (`ReportRepository`)**: `countDailyTrend()` (7 ngày), `countWeeklyTrend()` (8 tuần), `countMonthlyTrend()` (6 tháng) dùng SQL `GROUP BY` trực tiếp nên **không zero-fill các ngày/tuần/tháng bằng 0** và dùng `WEEK(created_at)` dễ lệch chuẩn đầu tuần — khác với `StaffTrend` và `UserTrend` đã dùng `TrendBucketHelper` (30 ngày / 12 tuần / 12 tháng, zero-fill đầy đủ).
   - **Thiếu đánh giá độ phức tạp khi đo hiệu suất Nhân viên**: `StaffServiceImpl.getStatistics` tính `workload` chỉ theo số lượng task (`processingCount`) và `efficiencyRate` chỉ theo tỷ lệ đúng hạn (`onTime / evaluated`), **chưa phân tầng hoặc gắn trọng số theo `EReportSeverity`** (`low`=3 ngày, `medium`=5 ngày, `high`=7 ngày, `critical`=10 ngày), dẫn đến nhân viên xử lý nhiều ca `critical` dễ bị nhìn nhận ngang bằng với nhân viên xử lý ca `low`.
   - **Thiếu bộ lọc thời gian cho thống kê Phản ánh và thống kê Người dùng**: `GET /admin/reports/statistics` luôn tính all-time; `GET /admin/users/statistics` cố định cửa sổ 30 ngày (`STATS_WINDOW_DAYS = 30`) và `topReporters` cố định all-time; đồng thời không trả về số lượng user `active` vs `blocked` (chưa có filter status trong `AdminUserController`).
   - **Thiếu trường phân loại nghiệp vụ & hành chính**: Bảng `reports` **không có** `category`/`issue_type`, **không có** `zone`/`ward`/`district` chuẩn hóa (chỉ có `address` dạng chuỗi tự do và `latitude`/`longitude`), và bảng `users` không có lịch sử đăng nhập/hoạt động ứng dụng (`last_login_at`).
   - **Không tồn tại nghiệp vụ tài chính**: Qua kiểm tra `DataInitializer.java` (dòng 60–74), toàn bộ bảng ví/hoa hồng/rút tiền (`staff_wallets`, `staff_wallet_transactions`, `staff_withdrawal_requests`, `wallet_configs`, `bonus_amount`) **đã bị xóa bỏ hoàn toàn khỏi hệ thống**.

---

## II. Bản đồ nghiệp vụ và dữ liệu

Bảng dưới đây ánh xạ chính xác các màn hình quản lý hiện có với nghiệp vụ thực tế, dữ liệu lưu trữ và chỉ số khai thác được từ source code:

| STT | Màn hình quản lý | Nghiệp vụ | Dữ liệu liên quan | Chỉ số có thể khai thác |
|---|---|---|---|---|
| 1 | `AdminHomeScreen` (`/home`) | Giám sát sức khỏe hệ thống tổng thể, phát hiện sự cố mới trong 1 giờ, nhận biết cảnh báo phản ánh chưa thỏa đáng và điều hướng nhanh | `users` (`role`, `status`, `createdAt`), `reports` (`status`, `severity`, `isReviewResolved`, `deadline`, `createdAt`, `resolvedAt`), `account_lock_requests` (`status`, `expiresAt`), `activity_histories`, `news` | • Số lượng user/staff/admin (active vs blocked)<br>• Backlog hiện tại (`pending`, `processing`, `rehandling`, `overdue`)<br>• Số phản ánh mới tạo hôm nay / 24h<br>• Số đề xuất khóa chờ biểu quyết / sắp hết hạn 72h<br>• Tốc độ thông qua/xử lý trong 7 ngày gần nhất |
| 2 | `AdminAllActivitiesScreen` (`/activities`) | Tra cứu nhật ký thao tác hệ thống của Admin, Staff và Client theo vai trò và chủ đề hành động | `activity_histories` (`id`, `actor_id`, `i18n_key`, `target_id`, `created_at`), `users` (`role`, `fullName`) | • Tần suất hoạt động theo loại sự kiện (`news`, `report_create`, `report_assign`, `report_process`, `report_reject`, `lock_request`, `staff`, `position`)<br>• Mức độ hoạt động điều phối của từng Admin (có sẵn `actor_id`) |
| 3 | `ReportDashboardScreen` (`/report-dashboard`) & `ReportListScreen` (`/report-list`) | Theo dõi tổng quan phản ánh, phân tích xu hướng phát sinh, lọc đa tiêu chí, chuyển trạng thái trên Kanban/Table | `reports` (`status`, `severity`, `createdAt`, `assignedAt`, `resolvedAt`, `rejectedAt`, `deadline`, `isReviewResolved`, `rating`, `reviewedAt`, `isAnonymous`, `assigned_staff_id`) | • Đếm theo trạng thái & mức độ (đã có)<br>• Tỷ lệ hoàn thành, tỷ lệ từ chối, tỷ lệ quá hạn<br>• Thời gian chờ phân công TB (`assignedAt - createdAt`)<br>• Thời gian xử lý TB (`resolvedAt - assignedAt`)<br>• So sánh tạo mới vs giải quyết vs từ chối theo thời gian<br>• Phân bố tuổi tồn đọng (`backlog aging`: <24h, 1-3d, 3-7d, >7d)<br>• Điểm rating TB & tỷ lệ hài lòng (`isReviewResolved = true`) |
| 4 | `UnsatisfactoryReportsScreen` (`/reports/unsatisfactory`) | Giám sát các phản ánh bị người dân đánh giá chưa thỏa đáng để Admin kiểm tra và mở lại (`reopen`) giao xử lý lại | `reports` (`isReviewResolved = false`, `status`, `reviewNote`, `reviewImageUrls`, `reviewedAt`, `assigned_staff_id`, `severity`) | • Tổng ca chờ duyệt xử lý lại vs đang làm lại (đã có)<br>• Tỷ lệ xử lý lại (`rehandling rate = unsatisfactory / reviewed`)<br>• Thời gian chờ Admin duyệt mở lại (`now - reviewedAt` khi status vẫn là `processed`)<br>• Phân bố ca chưa thỏa đáng theo nhân viên phụ trách & mức độ |
| 5 | `AdminReportDetailScreen` (`/reports/:id`) | Thẩm định chi tiết sự cố, phân công nhân viên + gán mức độ (`severity`), từ chối phản ánh (`rejectedReason`), mở lại phản ánh (`processed -> processing`) | `reports`, `users` (reporter & assignedStaff), `conversations` | • Phục vụ xử lý từng hồ sơ đơn lẻ; có thể hiển thị ngữ cảnh SLA/khối lượng hiện tại của nhân viên khi chọn phân công (`processingCount` đã có trong picker) |
| 6 | `AdminMapScreen` (`/space-map`) | Giám sát phân bố không gian sự cố theo bản đồ cụm (`cluster`) và bản đồ mật độ lục giác H3, phân công nhanh tại điểm nóng | `reports` (`latitude`, `longitude`, `status`, `severity`, `createdAt`, `deadline`, `assigned_staff_id`, `address`), Redis H3 cells (`map:density:*` Resolution 11) | • Số điểm sự cố & mật độ theo ô H3 (đã có trực quan hóa)<br>• Top N ô H3 / cụm khu vực có nhiều phản ánh nhất theo timeframe (`1m`, `3m`, `6m`, `9m`, `12m`, `all`)<br>• Tỷ trọng `pending` & `overdue` tại từng điểm nóng<br>• Mức độ biến động mật độ giữa kỳ hiện tại và kỳ trước theo ô H3<br>• Tỷ lệ phản ánh có/thiếu tọa độ hợp lệ |
| 7 | `StaffManagementScreen` (`/staff-management`) | Quản lý hồ sơ, chức vụ, khóa/mở khóa nhân viên; theo dõi KPI tháng, luồng vào/ra, khối lượng công việc và hiệu suất đúng hạn | `users` (`role=staff`, `status`, `position_id`), `reports` (`assignedStaff`, `status`, `severity`, `assignedAt`, `resolvedAt`, `deadline`, `isReviewResolved`, `rating`), `report_delegations` (`requester`, `helper`, `status`, `severity`, `createdAt`, `respondedAt`, `completedAt`) | • Đã có: Total/Active/Blocked, Processing, Resolved/month, Avg Resolution Time, Flow Assigned vs Resolved, Top 5 Workload, Deadline Performance<br>• Khai thác thêm: Workload có trọng số `severity`, Rating TB & tỷ lệ bị đánh giá lại theo staff, Tỷ lệ quá hạn đang mở, Thống kê nhờ làm giùm (`ReportDelegation`: tỷ lệ chấp nhận/từ chối/hết hạn, thời gian phản hồi TB), Thống kê theo `Position` |
| 8 | `PositionManagementScreen` (`/position-management`) | Quản lý danh mục chức vụ chuyên môn của nhân viên (CRUD, kích hoạt/tạm ngưng) | `positions` (`id`, `code`, `name`, `isActive`), `users` (`position_id`, `role=staff`) | • Đã có: Tổng chức vụ, Đang hoạt động, Tổng nhân viên đã gán (Web)<br>• Khai thác thêm: Nhân viên chưa gán chức vụ, phân bố khối lượng công việc đang xử lý theo từng chức vụ (tính từ `users.position_id` + `reports`) |
| 9 | `UserManagementScreen` (`/user-management`) | Quản lý tài khoản cư dân (`client`), xem hồ sơ, lịch sử phản ánh công khai và khởi tạo đề xuất khóa | `users` (`role=client`, `status`, `createdAt`, `language`, `gender`), `reports` (`user_id`, `isAnonymous`, `status`, `createdAt`, `reviewedAt`, `rating`), `account_lock_requests` (`target_id`, `status`) | • Đã có: Tổng user, User mới 30 ngày, Người gửi phản ánh 30 ngày, Phản ánh 30 ngày, Trend đăng ký, Top 5 đóng góp<br>• Khai thác thêm: Tỷ lệ tài khoản `active` vs `blocked`, Số phản ánh TB/người hoạt động, Tỷ lệ phản ánh ẩn danh vs công khai, Tỷ lệ người dùng tham gia đánh giá kết quả (`reviewedAt`), Khả năng lọc khoảng thời gian & xem Top đóng góp theo kỳ |
| 10 | `AdminBoardScreen` (`/admin-board`) | Quản trị hội đồng Admin (tạo/khóa/mở khóa Admin) và biểu quyết đề xuất khóa tài khoản cư dân (cần ≥2 phiếu đồng ý hoặc từ chối trong 72h) | `users` (`role=admin`, `status`), `account_lock_requests` (`status`, `createdAt`, `expiresAt`, `resolvedAt`, `proposer_id`, `target_id`), `account_lock_votes` (`decision`, `voter_id`, `createdAt`) | • Đã có: Tổng/Active/Blocked Admin; Đếm `awaitingMyVote`, `pending`, `resolved`<br>• Khai thác thêm: Phân rã kết quả biểu quyết (`approved`, `rejected`, `expired`, `cancelled`), Tỷ lệ đề xuất hết hạn (chưa kịp bỏ phiếu trong 72h), Thời gian xử lý biểu quyết TB (`resolvedAt - createdAt`), Tỷ lệ tham gia bỏ phiếu của Admin |
| 11 | `AdminNewsListScreen`, `AdminCreateEditNewsScreen`, `AdminNewsDetailScreen` (`/news*`) | Đăng tải, chỉnh sửa, xóa bản tin và gửi thông báo theo nhóm vai trò | `news` (`id`, `title`, `content`, `author_id`, `createdAt`, `updatedAt`) | • Chỉ có thể đếm tổng số bài viết và tần suất đăng bài theo tháng/tác giả.<br>• **Không thể** đo lượt xem/đọc vì DB không lưu view/read tracking |
| 12 | `AdminConversationsScreen`, `AdminChatDetailScreen`, `AdminConversationInfoScreen` (`/conversations`, `/chat/:id*`) | Trao đổi nội bộ giữa Admin với Staff/Admin khác (lưu ý: UI chặn Admin nhắn trực tiếp cho Client trong `UserDetailView` & `AdminReportDetailScreen`) | `conversations`, `conversation_participants` (`unreadCount`, `lastReadAt`), `chat_messages` (`sentAt`, `messageType`, `report_id`) | • Chỉ nên giữ badge unread hiện có; không có nhu cầu quản trị lớn để dựng dashboard riêng cho chat (có thể tận dụng đếm tin nhắn liên kết phản ánh nếu cần về sau) |
| 13 | `AdminNotificationScreen` (`/notifications`), `AdminSearchScreen` (`/search`), `Settings` (`/settings*`) | Nhận thông báo sự kiện, điều hướng nhanh, quản lý tài khoản cá nhân và thiết bị đăng nhập | `notifications`, `user_notification_states`, `device_tokens` (`platform`, `lastUsedAt`), Redis `RefreshTokenSession` | • Phục vụ thao tác cá nhân Admin; riêng `device_tokens` có thể cho biết phân bổ nền tảng (`android`/`ios`/`web`) nếu cần về mặt kỹ thuật, nhưng giá trị quản trị nghiệp vụ thấp |

---

## III. Danh sách Dashboard đề xuất

Dựa trên thực trạng hệ thống (đã có nền tảng ở 4 màn hình chính nhưng thiếu chiều sâu phân tích và thiếu góc nhìn không gian/chất lượng), báo cáo đề xuất **5 nhóm Dashboard** (trong đó 4 nhóm là **nâng cấp/tái cấu trúc có chọn lọc** tại đúng màn hình đang tồn tại để tránh trùng lặp, 1 nhóm mới là **Spatial Analytics Panel** trên Bản đồ) và **1 nhóm bị loại trừ có cơ sở** (Financial Analytics).

---

### Dashboard 1: Executive System Health & Early Warning (Nâng cấp `AdminHomeScreen`)

**1. Tên Dashboard:** Executive System Health & Early Warning Dashboard

**2. Vị trí hiển thị:**
- **Màn hình cụ thể:** `AdminHomeScreen` (`/home`).
- **Vị trí trong giao diện:** Phần đầu trang (ngay dưới `_buildDashboardHeader`, thay thế/tái cấu trúc khu vực `_buildOverviewSection` và bổ sung 1 khối **Actionable Alerts & 7-Day Pulse** phía trên cụm 2 cột `_buildRecentReportSection` / side panel).
- **Lý do lựa chọn vị trí:** `AdminHomeScreen` là trang mặc định sau đăng nhập (`RouterPath.home`). Admin cần nắm trong 5 giây đầu: hệ thống có đang ổn định không, có điểm nghẽn hoặc việc khẩn nào cần xử lý ngay (tồn đọng quá hạn, phản ánh chưa thỏa đáng, đề xuất khóa sắp hết hạn 72h, nhân viên quá tải), thay vì chỉ nhìn 7 con số tĩnh không có bối cảnh tăng/giảm.

**3. Mục đích:**
- Giúp Admin đánh giá nhanh **sức khỏe vận hành toàn hệ thống** và **ưu tiên hành động trong ngày**.
- Tránh trùng lặp với `ReportDashboardScreen`: Home chỉ giữ **KPI tổng hợp liên phân hệ** (User, Staff, Backlog tổng, SLA/Chất lượng tổng, Cảnh báo cần hành động) và **1 mini chart nhịp độ 7 ngày**; mọi phân tích sâu về phản ánh đi vào `/report-dashboard`.

**4. Các thành phần đề xuất:**

| STT | Thành phần | Loại hiển thị | Chỉ số / Nội dung | Công thức hoặc cách tính | Ý nghĩa |
|---|---|---|---|---|---|
| 1 | **Action Center Banner (Cảnh báo cần xử lý ngay)** | Alert Banner Cards (nhóm các cảnh báo có count > 0, click điều hướng thẳng tới hàng chờ) | 1. Phản ánh chờ phân công quá 24h<br>2. Phản ánh đang quá hạn (`overdue`)<br>3. Phản ánh chưa thỏa đáng chờ mở lại<br>4. Đề xuất khóa chờ bạn bỏ phiếu / sắp hết hạn <12h | 1. `COUNT(Report WHERE status='pending' AND createdAt < now - 24h)`<br>2. `COUNT(Report WHERE status IN ('pending','processing') AND deadline <= now)`<br>3. `COUNT(Report WHERE status='processed' AND isReviewResolved=false)` *(đã có)*<br>4. `AccountLockPendingCountResponse.awaitingMyVote` & `nextDeadlineAt` *(đã có)* | Gom toàn bộ việc khẩn cấp của Admin vào 1 điểm nhìn duy nhất, hỗ trợ xử lý ngay bằng 1 click |
| 2 | **System Pulse KPIs (4–6 thẻ gọn, có delta 7 ngày)** | KPI Cards (`KpiCard` có `KpiFootnote.change`) | 1. Người dùng hoạt động / Tổng user<br>2. Nhân viên sẵn sàng (`active / total`)<br>3. Phản ánh đang mở (`pending + processing` + `rehandling`)<br>4. Tỷ lệ đúng hạn 30 ngày (`onTimeRate`)<br>5. Điểm hài lòng TB 30 ngày (`avgRating`) | 1. `countByRole(client)` + `newUsers(7d)`<br>2. `countByRoleAndStatus(staff, active)` / `totalStaff`<br>3. `pending + processing` *(đã có)* + delta tạo mới 7d vs 7d trước<br>4. `completedOnTime / (completedOnTime + completedLate)` 30d<br>5. `AVG(rating)` của `Report` có `reviewedAt >= now - 30d AND isReviewResolved = true` | Cung cấp cái nhìn đa chiều (Quy mô – Tải – Tốc độ – Chất lượng) kèm ngữ cảnh tăng/giảm thay vì chỉ đếm số lượng thuần |
| 3 | **Nhịp độ vận hành 7 ngày (System 7-Day Pulse)** | Dual Line / Bar Chart (`TrendLineChart` / `BarChart`) | So sánh 2 chuỗi theo ngày (7 ngày gần nhất, zero-filled):<br>- Phản ánh tiếp nhận mới<br>- Phản ánh xử lý xong | Theo từng ngày $d \in [today-6, today]$:<br>- `Inflow(d) = COUNT(createdAt trong ngày d)`<br>- `Outflow(d) = COUNT(resolvedAt trong ngày d AND status='processed')` | Cho thấy ngay hệ thống đang **giải quyết nhanh hơn phát sinh** (`Outflow >= Inflow`) hay đang **tích tụ tồn đọng** (`Inflow > Outflow`) |

**5. Bộ lọc:**
- Trang Home giữ mặc định cố định theo ngữ cảnh real-time + 7/30 ngày gần nhất (không đặt bộ lọc phức tạp trên Home để giữ tốc độ tải và sự đơn giản; bộ lọc sâu nằm ở các dashboard chuyên biệt).

**6. Dữ liệu nguồn:**
- **Entities/Tables:** `users`, `reports`, `account_lock_requests`, `account_lock_votes`.
- **API hiện có:** `GET /admin/home/overview` (`AdminOverviewResponse`), `GET /admin/lock-requests/pending-count`.
- **Trường dữ liệu:** `Report.status`, `Report.createdAt`, `Report.resolvedAt`, `Report.deadline`, `Report.isReviewResolved`, `Report.rating`, `Report.reviewedAt`, `User.role`, `User.status`, `AccountLockRequest.status`, `AccountLockRequest.expiresAt`.

**7. Khả năng triển khai:**
- **Dữ liệu hiện có:** Đáp ứng ~95% cho các chỉ số đề xuất (toàn bộ các trường `createdAt`, `resolvedAt`, `deadline`, `rating`, `isReviewResolved` đều đã có).
- **Cần bổ sung API:** Mở rộng `GET /admin/home/overview` (hoặc thêm `GET /admin/home/pulse`) để trả về `pendingOver24hCount`, `overdueActiveCount`, `awaitingLockVotesCount`, `urgentLockVotesCount`, `onTimeRate30d`, `avgRating30d`, và mảng `pulse7Days` (`date`, `created`, `resolved`).
- **Cần thay đổi DB:** Không bắt buộc để triển khai ngay (tuy nhiên cần index `idx_reports_status_created_at`, `idx_reports_resolved_at` để tối ưu truy vấn).

**8. Giá trị quản trị:**
- Biến `AdminHomeScreen` từ bảng đếm trạng thái thụ động thành **trạm điều phối trung tâm (Command Center)**: Admin nhìn ra ngay tình trạng tồn đọng (Inflow vs Outflow), không bỏ sót các ca pending >24h hoặc biểu quyết khóa tài khoản sắp hết hạn 72h.

---

### Dashboard 2: Operational & Quality Analytics Dashboard (Nâng cấp `ReportDashboardScreen`)

**1. Tên Dashboard:** Operational & Quality Analytics Dashboard (Phân tích Vận hành & Chất lượng Xử lý Phản ánh)

**2. Vị trí hiển thị:**
- **Màn hình cụ thể:** `ReportDashboardScreen` (`/report-dashboard`).
- **Vị trí trong giao diện:**
  - Khu vực đầu trang (sau tiêu đề và **Filter Bar thời gian toàn cục của Dashboard**): Hàng KPI hiệu suất vận hành thay thế/bổ sung cho `ReportStatCards` hiện tại.
  - Khu vực biểu đồ giữa trang (trên danh sách `ReportTableView` / `ReportKanbanBoard`): Lưới 2 hàng biểu đồ (Hàng 1: Trend Inflow vs Outflow vs Rejected + Phân bố Mức độ & Trạng thái; Hàng 2: Tuổi tồn đọng Backlog Aging + Chất lượng đánh giá & Xử lý lại).
  - *Khuyến nghị dọn dẹp điều hướng:* Hợp nhất/chuyển hướng route `/report-list` (`ReportListScreen`) hoặc bỏ trùng lặp vì `ReportDashboardScreen` đã chứa sẵn danh sách Table/Kanban/Card bên dưới.
- **Lý do lựa chọn vị trí:** `ReportDashboardScreen` là màn hình trung tâm về nghiệp vụ xử lý sự cố. Đặt các chỉ số hiệu suất vận hành và chất lượng ngay phía trên bảng/Kanban giúp Admin vừa đánh giá hiệu quả quy trình (từ tiếp nhận → phân công → xử lý → nghiệm thu), vừa lọc thẳng xuống danh sách sự cố có vấn đề để can thiệp.

**3. Mục đích:**
- Đo lường **hiệu quả thông lượng (throughput)**, **tốc độ phản hồi (lead time & cycle time)**, **tình trạng nghẽn cổ chai (backlog aging)** và **chất lượng giải quyết thực tế** dưới góc nhìn người dân (`rating`, `isReviewResolved`).
- Hỗ trợ Admin trả lời: *"Phản ánh đang bị tắc ở khâu nào (chờ phân công hay đang xử lý)? Mất bao lâu để giải quyết? Chất lượng xử lý có làm cư dân hài lòng không?"*

**4. Các thành phần đề xuất:**

| STT | Thành phần | Loại hiển thị | Chỉ số / Nội dung | Công thức hoặc cách tính | Ý nghĩa |
|---|---|---|---|---|---|
| 1 | **Operational KPI Strip** | 5 KPI Cards (`KpiCard`) | 1. Tổng phản ánh trong kỳ & Tỷ lệ hoàn thành<br>2. Tồn đọng hiện hành & Số quá hạn<br>3. Thời gian chờ phân công TB (Lead Time)<br>4. Thời gian xử lý TB (Cycle Time)<br>5. Tỷ lệ hài lòng & Điểm Rating TB | 1. `Completion Rate = COUNT(status='processed') / COUNT(status != 'rejected') × 100%`<br>2. `Backlog = COUNT(status IN ('pending','processing'))`; `Overdue = COUNT(overdue)`<br>3. `AVG(assignedAt - createdAt)` (giờ/phút) với các report đã gán `assignedAt != null`<br>4. `AVG(resolvedAt - assignedAt)` (giờ) với `status='processed' AND assignedAt != null AND resolvedAt != null`<br>5. `Satisfaction Rate = COUNT(isReviewResolved=true) / COUNT(reviewedAt != null) × 100%`; `AVG(rating)` | Đánh giá toàn diện chu trình xử lý: không chỉ biết bao nhiêu ca xong mà còn biết **chờ duyệt mất bao lâu**, **làm mất bao lâu**, và **cư dân chấm mấy sao** |
| 2 | **Operational Flow Trend** | Multi-series Area/Line Chart (`TrendLineChart`, zero-filled) | Xu hướng theo ngày/tuần/tháng của 3 chuỗi:<br>- Tạo mới (`Created`)<br>- Hoàn thành (`Resolved`)<br>- Từ chối (`Rejected`) | Gom nhóm theo bucket `TrendBucketHelper`:<br>- `Created`: theo `createdAt`<br>- `Resolved`: theo `resolvedAt` (`status='processed'`)<br>- `Rejected`: theo `rejectedAt` (`status='rejected'`) | Khắc phục hạn chế hiện tại của `ReportTrendChart` (chỉ có 1 đường `createdAt` và thiếu zero-fill); giúp phát hiện sự cố tăng đột biến và độ trễ giải quyết |
| 3 | **Severity & Status Breakdown** | Donut Chart + Stacked Horizontal Bar | Phân bố theo `severity` (`low`, `medium`, `high`, `critical`) kết hợp tỷ trọng trạng thái trong từng mức độ | `GROUP BY severity, status` trên tập dữ liệu đã lọc | Giúp phát hiện nếu các ca `high`/`critical` vẫn nằm nhiều ở trạng thái `pending` hoặc `overdue` |
| 4 | **Backlog Aging (Tuổi tồn đọng)** | Vertical Bar Chart (`BarChart`) | Phân nhóm các phản ánh **chưa xong** (`pending` + `processing`) theo độ tuổi từ lúc tạo:<br>- `< 24 giờ`<br>- `1–3 ngày`<br>- `3–7 ngày`<br>- `> 7 ngày` | Tính `age = now - createdAt` cho từng report có `status IN ('pending', 'processing')`, tách 2 series màu theo `pending` (chờ giao) vs `processing` (đang làm) | Phát hiện "điểm mù" của trạng thái `pending`: nhiều ca chưa có staff nhận bị ngâm quá lâu dù chưa tới hạn xử lý |
| 5 | **Citizen Review & Rehandling Quality** | Summary Card + Rating Distribution Bar (1★ → 5★) | - Phân bố sao 1★–5★<br>- Tỷ lệ đã được đánh giá (`reviewed / processed`)<br>- Tỷ lệ chưa thỏa đáng (`isReviewResolved = false / reviewed`) | - `GROUP BY rating` với `rating IS NOT NULL`<br>- `Review Coverage = COUNT(reviewedAt != null) / COUNT(status='processed')`<br>- `Rehandling Rate = COUNT(isReviewResolved=false) / COUNT(reviewedAt != null)` | Đo lường chất lượng đầu ra thực sự; lưu ý gắn chú thích nguồn dữ liệu chỉ phản ánh **vòng đánh giá hiện tại** do hệ thống chưa lưu lịch sử review trước khi reopen |

**5. Bộ lọc:**
- **Khoảng thời gian thống kê** (`7 ngày`, `30 ngày`, `Tháng này`, `Quý này`, `Tùy chọn từ ngày – đến ngày`) áp dụng đồng bộ cho KPI & Charts (tách biệt hoặc đồng bộ rõ ràng với filter danh sách bên dưới).
- **Mức độ (`severity`)**: `all`, `low`, `medium`, `high`, `critical`.
- **Trạng thái (`status`)** & **Chỉ quá hạn (`overdueOnly`)** & **Nhân viên (`assigneeId`)**.

**6. Dữ liệu nguồn:**
- **Entities/Tables:** `reports`.
- **API hiện có:** `GET /admin/reports/statistics`, `GET /admin/reports/trend`, `GET /admin/reports`.
- **Trường dữ liệu:** `createdAt`, `assignedAt`, `resolvedAt`, `rejectedAt`, `deadline`, `status`, `severity`, `isReviewResolved`, `rating`, `reviewedAt`, `assigned_staff_id`.

**7. Khả năng triển khai:**
- **Dữ liệu hiện có:** **Có thể tính toán ngay** hầu hết chỉ số trên từ `reports`.
- **Cần bổ sung API:**
  - Cập nhật `GET /admin/reports/statistics` hỗ trợ query params `from`, `to`, `severity`, `assigneeId` và trả thêm `avgLeadTimeMinutes`, `avgCycleTimeMinutes`, `completionRate`, `rejectionRate`, `backlogAging` (`under24h`, `d1to3`, `d3to7`, `over7d`), `reviewStats` (`reviewedCount`, `avgRating`, `ratingDistribution`, `unsatisfactoryCount`).
  - Chuẩn hóa `GET /admin/reports/trend` dùng `TrendBucketHelper` (zero-fill + trả về cả `created`, `resolved`, `rejected`).
- **Cần thay đổi DB (cho giai đoạn hoàn thiện dữ liệu):** Hiện chưa cần đổi DB để ra phiên bản 1, nhưng **về dài hạn cần bổ sung bảng `report_status_history`** để không bị mất `assignedAt` / `resolvedAt` / `rating` của các lần xử lý trước khi bị `reopen` hoặc `delegation`.

**8. Giá trị quản trị:**
- Admin phát hiện chính xác **nút thắt cổ chai** (chờ Admin giao hay chờ Staff làm), theo dõi xu hướng tồn đọng thực tế và kiểm soát chất lượng nghiệm thu thay vì chỉ đếm số lượng hồ sơ.

---

### Dashboard 3: Staff Performance & Delegation Analytics (Nâng cấp `StaffManagementScreen`)

**1. Tên Dashboard:** Staff Performance, Complexity-Adjusted Workload & Delegation Analytics

**2. Vị trí hiển thị:**
- **Màn hình cụ thể:** `StaffManagementScreen` (`/staff-management` — cả `WebStaffView` và phần mở rộng `Statistics` trong `MobileStaffView`).
- **Vị trí trong giao diện:**
  - Giữ nguyên cấu trúc hiện có ở đầu trang (`StaffStatsMonthSelector`, `StaffKpiGrid`, hàng biểu đồ `StaffFlowChart` + `StaffWorkloadChart`, `StaffDeadlinePerformanceCard`) và **nâng cấp nội dung bên trong + bổ sung 2 khối ngay dưới `StaffDeadlinePerformanceCard` (trên bảng danh sách nhân viên)**:
    1. **Ma trận Hiệu suất & Chất lượng Nhân viên (Full Staff Performance Table / Tabs)** trong phần thống kê (kèm tab/toggle chuyển đổi giữa *Hiệu suất Deadline & Chất lượng* và *Nhờ làm giùm - Delegation*).
    2. **Phân bổ tải theo Chức vụ (`Position`)** tích hợp gọn vào bảng hoặc khối phụ.
- **Lý do lựa chọn vị trí:** `StaffManagementScreen` đã có sẵn bộ chọn tháng (`StaffStatsMonthSelector`) và pattern dashboard theo tháng. Nâng cấp tại chỗ giúp tránh phân mảnh sang một màn hình mới không cần thiết và giữ nguyên luồng click vào nhân viên → mở `showStaffDetailSheet` → lọc sang danh sách phản ánh của nhân viên đó.

**3. Mục đích:**
- **Đánh giá hiệu suất công bằng hơn**, khắc phục nhược điểm đánh giá chỉ bằng số lượng công việc: tính đến **độ phức tạp (`severity`)**, **tỷ lệ bị người dân đánh giá lại (`rehandling`)**, **điểm rating TB**, và **mức độ tự chủ vs nhờ làm giùm (`ReportDelegation`)**.
- Hỗ trợ Admin ra quyết định điều phối công bằng (tránh dồn việc cho nhân viên đang gánh nhiều ca `high`/`critical` hoặc có tồn đọng quá hạn cao), phát hiện nhân viên cần hỗ trợ/đào tạo lại.

**4. Các thành phần đề xuất:**

| STT | Thành phần | Loại hiển thị | Chỉ số / Nội dung | Công thức hoặc cách tính | Ý nghĩa |
|---|---|---|---|---|---|
| 1 | **Staff KPI Grid (Nâng cấp 4→5 hoặc bổ sung footnote)** | KPI Cards (`KpiCard`) | Giữ 4 KPI hiện có (`totalStaff`, `processingReports`, `resolved`, `avgResolutionMinutes`), bổ sung:<br>- **Điểm hài lòng TB đội ngũ** (hoặc tỷ lệ hoàn tất sạch lần đầu `First-Pass Resolution Rate`) | `First-Pass Rate = (processed - rehandled) / processed × 100%` *(hoặc dựa trên `isReviewResolved=true / reviewed`)*<br>`Team Avg Rating = AVG(rating)` của các report hoàn thành trong tháng | Ngăn hiện tượng "làm nhanh cho xong nhưng làm ẩu khiến dân đánh giá chưa thỏa đáng" |
| 2 | **Complexity-Weighted Workload Chart (Nâng cấp `StaffWorkloadChart`)** | Stacked Horizontal Bar Chart (hoặc mở rộng `RankedBarList`) | Khối lượng công việc **đang xử lý** của top nhân viên (mở rộng từ top 5 lên top 10 hoặc xem tất cả), chia màu theo **mức độ (`low`, `medium`, `high`, `critical`)** + điểm tải trọng số | `Weighted Load = 1×low + 2×medium + 3×high + 5×critical` *(hệ số cấu hình được; mặc định tham chiếu theo thời gian SLA 3/5/7/10 ngày)* | Phản ánh đúng áp lực công việc thực tế: 3 ca `critical` nặng hơn 3 ca `low`. Giúp Admin điều phối người nhận việc mới công bằng |
| 3 | **Staff Quality & Efficiency Matrix (Nâng cấp `StaffDeadlinePerformanceCard`)** | Expandable Ranked Table (không cắt cứng ở 5–8 dòng như hiện tại) | Mỗi nhân viên hiển thị:<br>- Đang xử lý / Quá hạn đang mở<br>- Hoàn thành đúng hạn / trễ hạn<br>- Tỷ lệ đúng hạn (`efficiencyRate`)<br>- Thời gian xử lý TB cá nhân<br>- Điểm rating TB & Số ca bị xử lý lại (`rehandlingCount`) | Tính theo `assignedStaff.id` trong tháng được chọn:<br>- `Avg Duration = AVG(resolvedAt - assignedAt)`<br>- `Rehandle Rate = rehandlingCount / totalHandled`<br>- `Avg Rating = AVG(rating)` | So sánh đa chiều (Tốc độ + Đúng hạn + Chất lượng) thay vì chỉ dựa vào 1 tỷ lệ đúng hạn |
| 4 | **Delegation Overview (Hoạt động Nhờ làm giùm)** | Compact Summary Strip + Top Requesters/Helpers List | - Tổng yêu cầu nhờ làm giùm trong tháng (`total`)<br>- Phân bổ trạng thái (`ACCEPTED/COMPLETED`, `DECLINED`, `EXPIRED`, `CANCELLED/REVOKED`)<br>- Thời gian phản hồi TB (`respondedAt - createdAt`)<br>- Nhân viên nhờ nhiều nhất / hỗ trợ nhiều nhất | Truy vấn trực tiếp `ReportDelegation` (`createdAt` trong tháng):<br>- `Acceptance Rate = (ACCEPTED + COMPLETED) / (Total - PENDING - CANCELLED - REVOKED)`<br>- `Expiry Rate = EXPIRED / Total` | Lần đầu tiên cho Admin thấy bức tranh điều chuyển nội bộ giữa các nhân viên; phát hiện nhân viên thường xuyên đẩy việc hoặc gánh việc hộ đồng nghiệp |
| 5 | **Workload theo Chức vụ (`Position`)** | Horizontal Bar Chart (chỉ hiện nếu hệ thống có >1 Position đang dùng) | Số nhân viên active, số task đang xử lý & số task đã xong theo từng `Position` | `JOIN User.position` nhóm theo `position.id` + nhóm "Chưa gán chức vụ" | Giúp Admin đánh giá năng lực đáp ứng theo từng tổ/chức vụ chuyên môn và phát hiện thiếu nhân sự ở vị trí nào |

**5. Bộ lọc:**
- **Tháng thống kê (`year`, `month`)** — đã có (`StaffStatsMonthSelector`).
- **Chức vụ (`positionId`)** — tái sử dụng bộ lọc Position hiện có để lọc cả bảng nhân viên và ma trận hiệu suất.
- **Trạng thái tài khoản (`active` / `blocked`)**.

**6. Dữ liệu nguồn:**
- **Entities/Tables:** `users`, `positions`, `reports`, `report_delegations`.
- **API hiện có:** `GET /admin/staffs/statistics`, `GET /admin/staffs/trend`, `GET /admin/positions`.
- **Trường dữ liệu:** `Report.assignedStaff`, `Report.status`, `Report.severity`, `Report.assignedAt`, `Report.resolvedAt`, `Report.deadline`, `Report.isReviewResolved`, `Report.rating`; `ReportDelegation.requester`, `ReportDelegation.helper`, `ReportDelegation.status`, `ReportDelegation.createdAt`, `ReportDelegation.respondedAt`, `ReportDelegation.completedAt`; `User.position`.

**7. Khả năng triển khai:**
- **Dữ liệu hiện có:** Đủ dữ liệu nguồn cho toàn bộ các chỉ số trên (`Report` + `ReportDelegation` + `Position` đều đã có sẵn trong DB).
- **Cần bổ sung API:**
  - Mở rộng `StaffStatisticsResponse` (`GET /admin/staffs/statistics`): thêm `severityBreakdown` trong `WorkloadItem`, `avgResolutionMinutes` & `avgRating` & `rehandlingTotal` cho từng `DeadlinePerformanceItem`, trả về đầy đủ danh sách (hoặc phân trang/top 20) thay vì giới hạn cứng 5, thêm block `delegationSummary` và `byPosition`.
- **Cần thay đổi DB:** Không bắt buộc để triển khai ngay. *(Lưu ý kỹ thuật cần ghi nhận: khi `ReportDelegationServiceImpl.accept` chạy, `Report.assignedAt` bị cập nhật sang thời điểm helper nhận task — nên khi tính thời gian xử lý của nhân viên hỗ trợ là chính xác từ lúc nhận, nhưng tổng thời gian bị trễ kể từ lần giao đầu tiên sẽ bị rút ngắn nếu không có `report_status_history`.)*

**8. Giá trị quản trị:**
- Đánh giá nhân viên công tâm dựa trên **độ khó công việc + tiến độ + chất lượng nghiệm thu**, phát hiện sớm tình trạng quá tải cục bộ hoặc lạm dụng cơ chế nhờ làm giùm.

---

### Dashboard 4: User Engagement & Account Governance Analytics (Nâng cấp `UserManagementScreen` & `AdminBoardScreen`)

**1. Tên Dashboard:** User Engagement & Governance Analytics

**2. Vị trí hiển thị:**
- **Màn hình cụ thể 1:** `UserManagementScreen` (`/user-management` — `WebUserView` / `MobileUserView`).
  - **Vị trí:** Giữ cụm KPI + 2 biểu đồ hiện tại ở đầu trang, nâng cấp bổ sung số liệu chất lượng tương tác và bộ lọc thời gian ngay trong cụm chart.
- **Màn hình cụ thể 2 (phần quản trị tài khoản):** `AdminBoardScreen` → Tab `LockRequestsTab` (`/admin-board?tab=lock-requests`).
  - **Vị trí:** Bổ sung **1 dải thống kê kết quả xử lý (Governance Mini-Metrics)** ngay cạnh/dưới 3 thẻ đếm hiện có (`Cần bạn`, `Đang chờ`, `Đã kết thúc`) khi người dùng ở tab Đã kết thúc hoặc thu gọn trong header của `LockRequestsTab` (chú ý giữ phong cách tối giản `achromatic-ledger` của tab này).
- **Lý do lựa chọn vị trí:** Phản ánh đúng 2 khía cạnh Admin đang quản lý ở 2 màn hình: (1) Mức độ đóng góp và tăng trưởng cộng đồng cư dân tại `UserManagementScreen`; (2) Hiệu lực quản trị vi phạm và kỷ luật biểu quyết tại `AdminBoardScreen`.

**3. Mục đích:**
- Giúp Admin nắm được: tốc độ tăng trưởng người dùng mới, mức độ tham gia phản ánh thực tế (loại trừ/đo lường tỷ lệ ẩn danh), mức độ tham gia đánh giá nghiệm thu của người dân, và tình trạng tài khoản bị khóa/mở khóa.
- **Giới hạn trung thực theo dữ liệu:** Hệ thống **không lưu lịch sử đăng nhập hay lượt mở app** (`RefreshTokenSession` chỉ lưu phiên còn hạn trên Redis), nên **không đề xuất** các chỉ số DAU/MAU, thời gian online hay số lượt xem tin tức.

**4. Các thành phần đề xuất:**

| STT | Thành phần | Loại hiển thị | Chỉ số / Nội dung | Công thức hoặc cách tính | Ý nghĩa |
|---|---|---|---|---|---|
| 1 | **User KPI Grid (Nâng cấp)** | 4 KPI Cards (`KpiCard`, có footnote) | 1. Tổng người dùng (`active` / `blocked`)<br>2. Người dùng mới (theo kỳ + % tăng trưởng)<br>3. Người dùng có tương tác gửi phản ánh (`activeReporters` & % trên tổng)<br>4. Số phản ánh TB / người hoạt động (`Avg Reports per Active Reporter`) | 1. `countByRole(client)` + `countByRoleAndStatus(client, active/blocked)`<br>2. `newUsers(T)` vs `newUsers(T_prev)`<br>3. `COUNT(DISTINCT r.user.id)` có `createdAt ∈ T` (đã có)<br>4. `COUNT(r WHERE r.user.role='client' AND createdAt ∈ T) / activeReporters(T)` | Bổ sung tỷ lệ tài khoản `active/blocked` (hiện chưa có trên API) và cường độ phản ánh trung bình của nhóm người dùng có tương tác |
| 2 | **User Growth & Participation Trend** | Multi-series Line Chart (`TrendLineChart`) | Kết hợp hoặc tab chuyển đổi trên `UserRegistrationTrendChart`:<br>- Đăng ký mới (`newUsers`)<br>- Người gửi phản ánh duy nhất (`activeReporters`) theo tuần/tháng | Gom nhóm `User.createdAt` và `COUNT(DISTINCT Report.user.id)` theo bucket tuần/tháng | Giúp Admin phân biệt: tăng trưởng người dùng mới có đi kèm tăng trưởng người thực sự dùng tính năng phản ánh hay không |
| 3 | **Public vs Anonymous & Review Participation** | 2 Compact Ratio Bars / Mini Cards | 1. Tỷ trọng phản ánh Công khai vs Ẩn danh (`isAnonymous`)<br>2. Tỷ lệ cư dân tham gia nghiệm thu (`reviewedAt != null` trên tổng phản ánh `processed`) | 1. `GROUP BY isAnonymous` trên `reports` trong kỳ<br>2. `COUNT(reviewedAt != null) / COUNT(status='processed') × 100%` | Đánh giá mức độ tin tưởng (tỷ lệ ẩn danh cao có thể báo hiệu tâm lý ngại va chạm hoặc phản ánh nhạy cảm) và mức độ hợp tác đánh giá sau xử lý |
| 4 | **Top Contributors (Có lọc theo kỳ & không lộ ẩn danh)** | `RankedBarList` (đã có, nâng cấp lọc kỳ) | Top 5–10 người đóng góp phản ánh công khai nhiều nhất theo `30 ngày` / `Tháng này` / `All-time` (giữ nguyên rule **loại trừ `isAnonymous = true`** để bảo vệ quyền riêng tư) | `SELECT user.id, fullName, avatarUrl, COUNT(r) WHERE isAnonymous = false AND createdAt ∈ T GROUP BY user.id ORDER BY COUNT(r) DESC` | Nhận diện nhóm cư dân tích cực trong giai đoạn gần đây thay vì chỉ thấy danh sách tích lũy all-time |
| 5 | **Account Lock Governance Summary (Tại `LockRequestsTab`)** | Compact Stat Pills / Strip | Phân rã nhóm `Đã kết thúc`:<br>- Đã thông qua (`approved`)<br>- Đã bác bỏ (`rejected`)<br>- Hết hạn 72h (`expired`)<br>- Đã hủy (`cancelled`)<br>+ Thời gian biểu quyết TB | `GROUP BY status` trên `account_lock_requests`; `AVG(resolvedAt - createdAt)` với status in (`approved`, `rejected`) | Giúp Hội đồng Admin kiểm soát tỷ lệ đề xuất bị **hết hạn do thiếu phiếu kịp thời (`expired`)** — dấu hiệu cảnh báo sự chậm trễ trong điều hành |

**5. Bộ lọc:**
- Trên `UserManagementScreen`: Bộ chọn khoảng thời gian (`30 ngày`, `90 ngày`, `Toàn thời gian`) + Bộ lọc trạng thái tài khoản (`all`, `active`, `blocked`) cho bảng danh sách User (hiện chưa có).
- Trên `LockRequestsTab`: Bộ lọc theo trạng thái (`awaiting_mine`, `pending`, `resolved` — mở rộng filter phụ `approved`/`rejected`/`expired` nếu cần).

**6. Dữ liệu nguồn:**
- **Entities/Tables:** `users`, `reports`, `account_lock_requests`, `account_lock_votes`.
- **API hiện có:** `GET /admin/users/statistics`, `GET /admin/users/trend`, `GET /admin/users`, `GET /admin/lock-requests/pending-count`.
- **Trường dữ liệu:** `User.role`, `User.status`, `User.createdAt`, `Report.user`, `Report.isAnonymous`, `Report.createdAt`, `Report.status`, `Report.reviewedAt`, `AccountLockRequest.status`, `AccountLockRequest.createdAt`, `AccountLockRequest.resolvedAt`.

**7. Khả năng triển khai:**
- **Dữ liệu hiện có:** **Có thể tính toán ngay** từ `users`, `reports` và `account_lock_requests`.
- **Cần bổ sung API:**
  - Mở rộng `GET /admin/users/statistics` (thêm param `days` hoặc `from`/`to`, trả thêm `activeUsers`, `blockedUsers`, `avgReportsPerActiveReporter`, `anonymousCount`, `publicCount`, `reviewedCount`, `processedCount` và `topReporters` theo kỳ).
  - Bổ sung param `status` cho `GET /admin/users`.
  - Mở rộng `GET /admin/lock-requests/pending-count` (hoặc thêm `/admin/lock-requests/statistics`) trả về breakdown `approved`, `rejected`, `expired`, `cancelled` và `avgResolutionHours`.
- **Cần thay đổi DB:** Không bắt buộc. *(Lưu ý: chỉ bổ sung bảng `user_login_logs` nếu sau này thực sự muốn đo DAU/MAU).*

**8. Giá trị quản trị:**
- Theo dõi sức khỏe cộng đồng người dùng thực chất (không chỉ đếm tài khoản đăng ký ảo), phát hiện nhanh tình trạng chậm bỏ phiếu trong Hội đồng Admin và quản lý tập người dùng bị khóa hiệu quả hơn.

---

### Dashboard 5: Spatial Hotspot & Risk Analytics Dashboard (Tích hợp tại `AdminMapScreen`)

**1. Tên Dashboard:** Spatial Hotspot & Risk Analytics Panel

**2. Vị trí hiển thị:**
- **Màn hình cụ thể:** `AdminMapScreen` (`/space-map`).
- **Vị trí trong giao diện:**
  - **Trên Web/Desktop:** Một **Collapsible Analytics Side Drawer / Floating Panel** (rộng ~340–380px bên phải hoặc bên trái, có nút thu gọn/mở rộng) hoặc thanh **Viewport Summary Strip** ở cạnh trên bản đồ, đảm bảo không che khuất vùng bản đồ tác nghiệp chính.
  - **Trên Mobile:** Một **Draggable Bottom Sheet / Pill tổng hợp** ở đáy màn hình bản đồ (nhấn vào để kéo lên xem danh sách điểm nóng).
- **Lý do lựa chọn vị trí:** Bản đồ số là công cụ cốt lõi của SmartSpace (`PRODUCT.md`: *"Bản đồ là trung tâm"*). Hiện tại Admin nhìn thấy các lục giác đỏ/cam/xanh (`DensityMapLayer`) nhưng phải tự zoom/di chuyển thủ công để đoán khu vực nào nghiêm trọng nhất. Đặt bảng xếp hạng điểm nóng ngay trên màn hình bản đồ cho phép Admin **bấm vào 1 điểm nóng → bản đồ tự động `fly_to` tới tọa độ ô H3 đó** để xem danh sách phản ánh và phân công ngay.

**3. Mục đích:**
- Chuyển hóa dữ liệu tọa độ (`latitude`, `longitude`) và lưới lục giác **Uber H3 Resolution 11** thành danh sách **các khu vực ưu tiên kiểm tra (Top Hotspots)** kèm mức độ khẩn cấp (`pending`, `overdue`, `high/critical`).
- Hỗ trợ Admin trả lời: *"Khu vực nào đang phát sinh nhiều sự cố nhất trong 1 tháng/3 tháng qua? Điểm nóng nào đang có nhiều phản ánh chưa xử lý hoặc quá hạn cần điều phối gấp?"*

**4. Các thành phần đề xuất:**

| STT | Thành phần | Loại hiển thị | Chỉ số / Nội dung | Công thức hoặc cách tính | Ý nghĩa |
|---|---|---|---|---|---|
| 1 | **Viewport / Filtered Spatial KPI Strip** | 3–4 Mini Stat Pills | Trên tập phản ánh khớp bộ lọc hiện tại:<br>- Tổng điểm sự cố có tọa độ<br>- Số điểm chờ xử lý (`pending`)<br>- Số điểm mức độ cao/khẩn (`high + critical`)<br>- Tỷ lệ phản ánh thiếu tọa độ (cảnh báo chất lượng dữ liệu) | Tính trực tiếp trên kết quả `findAdminMapReports` / truy vấn DB khớp filter; `Missing Geo = COUNT(lat IS NULL OR lng IS NULL)` | Admin biết ngay trong phạm vi/bộ lọc đang xem có bao nhiêu ca chưa giao và ca nghiêm trọng |
| 2 | **Top Spatial Hotspots (Xếp hạng điểm nóng H3)** | Ranked List tương tác (`RankedBarList` + nút `Fly To`) | Top 10 ô H3 (hoặc cụm H3 Resolution 10/11) có mật độ cao nhất trong `timeframe` đang chọn:<br>- Tên địa chỉ đại diện (lấy từ `Report.address` phổ biến nhất trong ô)<br>- Tổng số phản ánh (`count`)<br>- Số `pending` & `high/critical` trong ô<br>- Tỷ lệ tăng/giảm so với kỳ trước (ví dụ `1m` hiện tại vs `1m` trước đó) | Dùng `H3Core.latLngToCellAddress(lat, lng, resolution)` gom nhóm các `Report` hợp lệ (không `rejected`):<br>`Risk Score = pending×2 + high_or_critical×3 + overdue×4` hoặc xếp hạng theo `count` + badge rủi ro | **Chức năng hành động cao:** Click 1 dòng → bản đồ `fly_to(cell.latitude, cell.longitude, zoom: 17)` đúng vị trí điểm nóng |
| 3 | **Hotspot Recurrence & Persistence (Khu vực tái phát)** | Alert Tag / List | Những ô H3 xuất hiện phản ánh liên tục qua nhiều tháng (vd: có phản ánh ở cả `1m`, `3m`, `6m`) hoặc có nhiều ca bị `isReviewResolved = false` | Đếm số tháng distinct có `createdAt` trong cùng cell H3 (`COUNT(DISTINCT DATE_FORMAT(created_at, '%Y-%m'))`) | Phân biệt sự cố nhất thời với **điểm đen hạ tầng thường xuyên tái phát** cần kiểm tra gốc rễ |
| 4 | **Severity × Density Matrix (Hoặc lọc nhanh theo mức độ trên bản đồ)** | Mini Bar / Filter Chips | Phân bố mức độ `low`/`medium`/`high`/`critical` của các điểm đang hiển thị | `GROUP BY severity` trên tập báo cáo đang lọc | Giúp Admin nhìn nhanh bản đồ hiện tại có đang tập trung sự cố nghiêm trọng hay không |

**5. Bộ lọc:**
- Đồng bộ 100% với bộ lọc bản đồ hiện có (`MapFilterPanel` / `MapSettingsBottomSheet`): `timeframe` (`all`, `1m`, `3m`, `6m`, `9m`, `12m`), `status`, `severity`, `assigneeId`, khoảng ngày `from`–`to`, và tùy chọn **Chỉ trong khung nhìn hiện tại (Current Viewport)** vs **Toàn khu vực**.

**6. Dữ liệu nguồn:**
- **Entities/Tables:** `reports` (`id`, `latitude`, `longitude`, `address`, `status`, `severity`, `createdAt`, `deadline`, `isReviewResolved`).
- **Hạ tầng sẵn có:** `ReportDensityServiceImpl` (đã tích hợp sẵn thư viện `com.uber.h3core.H3Core` v4 và Redis).
- **API hiện có:** `GET /admin/reports/map`, `GET /reports/density`.

**7. Khả năng triển khai:**
- **Dữ liệu hiện có:** **Đầy đủ dữ liệu nguồn** (`latitude`, `longitude`, `createdAt`, `status`, `severity`, `address` đã lưu trên mọi `Report` vị trí).
- **Cần bổ sung API:**
  - Thêm endpoint `GET /admin/reports/spatial-analytics` (hoặc mở rộng dữ liệu trả về) nhận `timeframe`, `status`, `severity`, tùy chọn bounds `minLat/maxLat/minLng/maxLng` để trả về: `totalWithCoords`, `totalWithoutCoords`, `topHotspots` (cellId, centerLat, centerLng, sampleAddress, totalCount, pendingCount, overdueCount, highCriticalCount, prevPeriodCount, activeMonthsCount).
  - Trên Web (`admin_map_screen_web.dart`), tận dụng message `fly_to` đã có sẵn (dòng 254) để bay tới cell được chọn.
- **Cần thay đổi DB:** Không bắt buộc để chạy với H3 từ `latitude`/`longitude`. *(Ghi chú: nếu sau này trường/khu vực muốn thống kê theo tên tòa nhà/khu A-B-C chính xác 100% thay vì ô lục giác và chuỗi `address` tự do, cần thêm bảng `zones` / cột `zone_id` vào `reports` — hiện tại **Chưa có**).*

**8. Giá trị quản trị:**
- Tận dụng triệt để thế mạnh GIS + Uber H3 vốn có của SmartSpace, giúp Admin **chủ động phát hiện điểm đen không gian**, ưu tiên nguồn lực kiểm tra hiện trường và đối chiếu biến động giữa các tháng.

---

### Đánh giá nhóm Financial Analytics Dashboard (Mục 3.6 của yêu cầu)

**Kết luận: KHÔNG ĐỀ XUẤT TRIỂN KHAI.**
- **Căn cứ kiểm chứng từ source code:**
  - Trong `SmartSpace_Backend/src/main/java/com/vn/smart_space/configuration/DataInitializer.java` (dòng 60–74), hệ thống có đoạn dọn dẹp DB:
    `DROP TABLE IF EXISTS staff_wallet_transactions`, `staff_withdrawal_requests`, `staff_wallets`, `staff_bank_accounts`, `wallet_configs`, cùng các cột `base_commission`, `total_commission_deducted`, `commission_awarded`, `bonus_amount`.
  - Kiểm tra toàn bộ `model/*.java`, `controller/**/*.java` và `smartspace_admin/lib/**` xác nhận **không còn bất kỳ entity, API hay màn hình quản lý ví/rút tiền/hoa hồng/thanh toán nào** đang hoạt động (chỉ còn vài dòng comment cũ nhắc chữ "bonus" trong `EDelegationStatus.java` và `IReportDelegationService.java`).
- **Tuân thủ nguyên tắc:** Không đề xuất chỉ số tài chính, rút tiền, doanh thu hay giao dịch thanh toán khi hệ thống không thực sự có nghiệp vụ tương ứng.

---

## IV. Đề xuất Smart Analytics và Predictive Dashboard

Nguyên tắc cốt lõi: **Không dùng AI/Machine Learning hình thức** khi dữ liệu còn ít hoặc khi thống kê cổ điển giải quyết minh bạch và chính xác hơn. Dưới đây là phân tách rõ **những tính năng triển khai ngay bằng thống kê/rule-based** và **những tính năng cần tích lũy thêm dữ liệu/hạ tầng**.

### 4.1. Nhóm triển khai được NGAY (Thống kê mô tả, Z-score / EWMA & Rule-based — Không cần ML)

| STT | Tính năng thông minh | Loại | Dữ liệu đầu vào hiện có | Phương pháp thực hiện khả thi (Không cần ML) | Độ tin cậy & Giới hạn | Vị trí đề xuất |
|---|---|---|---|---|---|---|
| 1 | **Phát hiện tăng đột biến phản ánh (Volume Spike & Anomaly Detection)** | Phát hiện bất thường + Cảnh báo | Chuỗi đếm phản ánh theo ngày (`reports.createdAt`, 30–60 ngày gần nhất) | Tính trung bình trượt 14 ngày ($\mu_{14}$) và độ lệch chuẩn ($\sigma_{14}$). Cảnh báo nếu số lượng hôm nay/24h vượt ngưỡng $\mu_{14} + 2\sigma_{14}$ (Z-score $\ge 2$) hoặc tăng $\ge 50\%$ so với trung bình tuần trước (kèm điều kiện tối thiểu $N \ge 5$ để tránh nhiễu khi số liệu nhỏ). | **Cao & minh bạch**, dễ giải thích cho Admin; không bị "hộp đen" | `AdminHomeScreen` (Alert Center) & `ReportDashboardScreen` (điểm đánh dấu trên `ReportTrendChart`) |
| 2 | **Cảnh báo rủi ro trễ hạn SLA sớm (Early SLA Breach Warning)** | Dự báo rủi ro ngắn hạn + Cảnh báo | `Report.status`, `Report.deadline`, `Report.assignedAt`, `Report.severity`, `avgResolutionMinutes` | Tính tiến độ thời gian còn lại: `remaining / totalAllowedWindow`. Gắn cờ **At-Risk (Sắp trễ hạn)** cho các phản ánh `pending` chưa ai nhận đã quá 50% thời gian SLA, hoặc `processing` còn dưới 24h tới `deadline` (hoặc nhỏ hơn `avgResolutionMinutes` theo mức `severity` đó). | **Rất cao** (dựa trên dữ liệu thời gian thực chính xác của từng hồ sơ) | `AdminHomeScreen` (Alert Center), `ReportDashboardScreen` (tab/chip "Sắp trễ hạn") |
| 3 | **Phát hiện quá tải nhân viên & Gợi ý điều phối (Workload Overload Alert & Assignment Hint)** | Cảnh báo + Gợi ý hành động | `Staff.processingCount`, `severity` các task đang giữ, `overdueCount`, `Staff.status` | Tính `Weighted Load` theo trọng số mức độ; cảnh báo khi nhân viên vượt ngưỡng trung bình đội ngũ $\times 1.5$ hoặc đang có $\ge 2$ ca `overdue`. Khi Admin mở picker phân công nhân viên ở `AdminReportDetailScreen` / `MapQuickAssignSheet`, **gắn nhãn gợi ý "Tải nhẹ / Phù hợp"** (ưu tiên staff active, tải thấp, không có ca overdue, có chức vụ phù hợp nếu có). | **Cao**; hỗ trợ trực tiếp thao tác phân công hằng ngày của Admin | `StaffManagementScreen` + Picker phân công tại `AdminReportDetailScreen` & `AdminMapScreen` |
| 4 | **Phát hiện điểm nóng gia tăng theo ô H3 (Spatial Hotspot Acceleration)** | Phân tích xu hướng không gian + Cảnh báo | `reports.latitude`, `reports.longitude`, `reports.createdAt`, Uber H3 Cell ID | So sánh mật độ từng ô H3 trong 30 ngày gần nhất ($C_{30d}$) với trung bình 30 ngày của 90 ngày trước đó ($C_{prev\_avg}$). Đánh dấu **Khu vực bùng phát mới / Tăng nhanh** nếu $C_{30d} \ge 3$ và tăng $\ge 100\%$ so với kỳ trước, hoặc có mật độ `pending + overdue` cao nhất. | **Trung bình–Cao** (phụ thuộc mật độ dữ liệu thực tế trong trường học) | `AdminMapScreen` (Spatial Hotspot Panel) |
| 5 | **Nhận diện hồ sơ kéo dài bất thường (Long-Running Bottleneck Detection)** | Phát hiện bất thường | `Report.createdAt`, `assignedAt`, `resolvedAt`, `severity`, `isReviewResolved` | Tính phân vị thứ 90 ($P_{90}$) hoặc $\mu + 1.5 \times IQR$ của thời gian xử lý theo từng mức `severity`. Đánh dấu các ca đang `processing` có thời gian xử lý vượt ngưỡng $P_{90}$ của cùng mức `severity` là **"Kéo dài bất thường"**. | **Cao** khi hệ thống tích lũy tối thiểu ~30–50 phản ánh đã hoàn thành mỗi nhóm `severity` | `ReportDashboardScreen` & `StaffManagementScreen` |

### 4.2. Nhóm cần tích lũy thêm dữ liệu / nâng cấp cấu trúc trước khi triển khai

| STT | Tính năng nâng cao | Dữ liệu còn thiếu / Rào cản hiện tại | Phương pháp khuyến nghị khi đủ dữ liệu | Điều kiện tiên quyết để triển khai |
|---|---|---|---|---|
| 1 | **Dự báo khối lượng phản ánh theo tuần/tháng (Short-term Volume Forecasting)** | Dự báo chuỗi thời gian (đặc biệt trong môi trường trường học có tính mùa vụ học kỳ – nghỉ hè – mùa mưa) cần dữ liệu lịch sử tối thiểu **6–12 tháng liên tục**. Hiện chưa đủ dữ liệu lịch sử dài hạn và chưa có biến ngữ cảnh lịch học. | Khi có $\ge 3$ tháng: dùng **Seasonal Moving Average / Holt-Winters Exponential Smoothing** (đơn giản, không cần Deep Learning). Chỉ cân nhắc Prophet/Time-series model khi có $\ge 12$ tháng dữ liệu. | Tích lũy dữ liệu `reports.createdAt` tối thiểu 12–24 tuần; hiển thị kèm dải tin cậy (confidence interval) và ghi rõ là số liệu dự báo. |
| 2 | **Dự đoán nguy cơ tái phát / xử lý lại (`Rehandling Risk`) & Phân loại chủ đề sự cố tự động** | Hiện **không có cột `category`** trên `Report` và **không có bảng `report_status_history`** (nên mất lịch sử các lần xử lý lại trước đó). | Bổ sung `category` cho form tạo phản ánh (Client tự chọn hoặc gợi ý từ khóa/NLP nhẹ khi nhập `title`/`description`); lưu lịch sử reopen vào `report_status_history` để thống kê tỷ lệ tái phát theo `(category, zone/H3 cell)`. | Bổ sung schema DB (`category`, `report_status_history`) và thu thập dữ liệu tối thiểu vài trăm bản ghi đã nghiệm thu. |
| 3 | **Gợi ý nhân viên tối ưu theo chuyên môn & khoảng cách (`Smart Routing`)** | Nhân viên (`User` role `staff`) chỉ có `position`, **không lưu kỹ năng/khu vực phụ trách hay vị trí hiện trường lịch sử** để khớp với loại sự cố. | Dùng hệ thống chấm điểm đa tiêu chí minh bạch (Weighted Scoring: tải hiện tại + tỷ lệ đúng hạn + matching giữa `Report.category` và `Position`), **không cần ML**. | Bổ sung mapping giữa `Position` và `Report.category` (hoặc khu vực phụ trách). |

---

## V. Đề xuất bố cục tổng thể giao diện Admin

Nguyên tắc sắp xếp: **Tích hợp theo ngữ cảnh sử dụng (Contextual Analytics)**, không tạo thêm quá nhiều trang dashboard rời rạc khiến Admin phải chuyển qua lại, đồng thời loại bỏ màn hình dư thừa (`/report-list` trùng với phần dưới của `/report-dashboard`).

| Giao diện | Dashboard / Khối phân tích đề xuất | Vị trí | Mục đích |
|---|---|---|---|
| **Tổng quan Admin (`AdminHomeScreen`, `/home`)** | **1. Executive System Health & Early Warning**<br>- Action Center Banner (Pending >24h, Overdue, Chưa thỏa đáng, Phiếu khóa chờ duyệt)<br>- 5 System Pulse KPI Cards (có delta 7d/30d)<br>- Biểu đồ mini *System 7-Day Pulse* (Inflow vs Outflow) | Đầu trang (ngay dưới Header; *Pulse* đặt đầu cột trái hoặc ngay dưới KPI trước *Phản ánh gần đây*) | Cho Admin bức tranh tổng thể tức thì khi vừa đăng nhập và điều hướng 1-click tới mọi điểm nóng cần xử lý ngay |
| **Quản lý Phản ánh (`ReportDashboardScreen`, `/report-dashboard`)** | **2. Operational & Quality Analytics**<br>- Bộ lọc thời gian/mức độ toàn cục<br>- Operational KPI Strip (Lead Time, Cycle Time, Completion Rate, Backlog, Satisfaction/Rating)<br>- Biểu đồ *Operational Flow Trend* (Created vs Resolved vs Rejected)<br>- Biểu đồ *Severity × Status*, *Backlog Aging*, *Citizen Rating & Rehandling* | Đầu trang (phía trên `ReportFilterBar` và bảng Table/Kanban danh sách phản ánh) | Đánh giá hiệu suất quy trình xử lý, phát hiện khâu tắc nghẽn và chất lượng giải quyết trước khi đi sâu vào từng ticket |
| **Bản đồ Không gian (`AdminMapScreen`, `/space-map`)** | **3. Spatial Hotspot & Risk Analytics Panel**<br>- Spatial KPI Strip (điểm có tọa độ, pending, high/critical)<br>- Top 10 H3 Hotspots (kèm địa chỉ đại diện, risk score, delta kỳ trước & nút `Fly To`)<br>- Danh sách điểm đen tái phát | Cạnh phải/trái dạng Collapsible Side Panel (Web/Desktop) hoặc Draggable Bottom Sheet (Mobile) trên nền bản đồ | Kết hợp trực quan bản đồ nhiệt H3 với số liệu định lượng, giúp điều phối kiểm tra hiện trường đúng trọng tâm |
| **Quản lý Nhân viên (`StaffManagementScreen`, `/staff-management`)** | **4. Staff Performance & Delegation Analytics**<br>- Nâng cấp `StaffKpiGrid` (+ First-Pass Rate / Rating)<br>- Nâng cấp `StaffWorkloadChart` (xếp chồng theo `severity`)<br>- Nâng cấp `StaffDeadlinePerformanceCard` (mở rộng đầy đủ + Avg Time + Rating + Rehandle)<br>- Khối mới: *Delegation Overview* & *Workload theo Position* | Đầu trang (giữ nguyên bên dưới `StaffStatsMonthSelector`, phía trên bảng danh sách nhân viên; Mobile giữ dạng mở rộng thu gọn được) | Đánh giá nhân viên công bằng theo độ khó công việc và chất lượng nghiệm thu, giám sát hoạt động nhờ làm giùm |
| **Quản lý Người dùng (`UserManagementScreen`, `/user-management`)** | **5a. User Engagement Analytics**<br>- Nâng cấp `UserKpiGrid` (+ tỷ lệ Active/Blocked, Avg Reports/Active Reporter)<br>- Nâng cấp `UserRegistrationTrendChart` (+ Active Reporters trend)<br>- Mini Bar *Public vs Anonymous* & *Review Participation*<br>- `TopContributorsChart` có bộ lọc kỳ | Đầu trang (phía trên thanh tìm kiếm và bảng người dùng; Mobile giữ trong block thu gọn) | Theo dõi tăng trưởng và chất lượng tương tác thực chất của cộng đồng cư dân |
| **Hội đồng Quản trị (`AdminBoardScreen` → `LockRequestsTab`, `/admin-board`)** | **5b. Governance Voting Summary**<br>- Breakdown kết quả (`approved`, `rejected`, `expired`, `cancelled`) & Thời gian biểu quyết TB | Ngay dưới 3 thẻ đếm hiện có (hoặc trong strip tóm tắt đầu tab) | Theo dõi hiệu lực xử lý kỷ luật và phát hiện tình trạng đề xuất bị hết hạn 72h |
| **Chi tiết Phản ánh (`AdminReportDetailScreen`, `/reports/:id`)** | **Contextual Helper Badge (Không phải Dashboard)**<br>- Gắn thẻ cảnh báo SLA (`At-Risk`) & gợi ý tải nhẹ/trùng vị trí trong `_StaffPickerBottomSheet` | Inline trong thẻ trạng thái & Bottom sheet chọn nhân viên | Hỗ trợ Admin ra quyết định chọn nhân viên nhanh và chính xác ngay tại thời điểm phân công |

---

## VI. Phân loại mức độ ưu tiên

### P0 – Essential (Triển khai trước — Giá trị quản trị cao, dữ liệu có sẵn 100%)
1. **Operational & Quality Analytics Dashboard (`ReportDashboardScreen`)**:
   - *Lý do:* Phản ánh sự cố là nghiệp vụ lõi của toàn hệ thống. Hiện `ReportDashboardScreen` mới chỉ đếm số lượng tồn kho all-time và thiếu hoàn toàn Lead Time, Cycle Time, Backlog Aging, Inflow vs Outflow và Citizen Rating/Satisfaction. Dữ liệu nguồn trên bảng `reports` đã có đủ, có thể tính toán và triển khai ngay để nâng cấp giá trị điều hành cốt lõi.
2. **Executive System Health & Early Warning (`AdminHomeScreen`)**:
   - *Lý do:* Là màn hình đầu tiên Admin mở mỗi ngày. Việc bổ sung Action Center Banner (gom `pending >24h`, `overdue`, `unsatisfactory`, `awaitingMyVote`), các chỉ số tỷ lệ chất lượng và biểu đồ 7-Day Pulse Inflow/Outflow mang lại giá trị ra quyết định ngay lập tức với chi phí API thấp.

### P1 – Important (Triển khai tiếp theo — Nâng chiều sâu điều phối & GIS)
3. **Staff Performance & Delegation Analytics (`StaffManagementScreen`)**:
   - *Lý do:* Màn hình Staff đã có sẵn dashboard khá tốt (Flow, Top 5 Workload, Deadline Performance). Tuy nhiên, việc nâng cấp thêm **trọng số theo `severity`**, **Citizen Rating & Rehandling theo từng nhân viên**, mở rộng full danh sách và bổ sung **Delegation Overview (`report_delegations`)** là bước quan trọng để tránh đánh giá phiến diện theo số lượng đơn thuần.
4. **Spatial Hotspot & Risk Analytics Panel (`AdminMapScreen`)**:
   - *Lý do:* Hệ thống đã có sẵn `H3Core` + Redis density cache, đây là điểm mạnh khác biệt của SmartSpace. Bổ sung bảng xếp hạng điểm nóng tương tác (`Fly To`) và cảnh báo điểm nóng tăng nhanh giúp bản đồ thực sự phục vụ ra quyết định thay vì chỉ để quan sát trực quan.
5. **User Engagement & Governance Analytics (`UserManagementScreen` & `LockRequestsTab`)**:
   - *Lý do:* Hiện `UserManagementScreen` đã có nền tảng 4 KPI + 2 chart; các phần bổ sung (active/blocked user, tỷ lệ ẩn danh, tỷ lệ tham gia đánh giá, lọc kỳ Top Contributors, breakdown kết quả biểu quyết khóa) rất hữu ích cho quản trị cộng đồng nhưng mức độ cấp bách vận hành hằng ngày thấp hơn P0 và Staff/Spatial.

### P2 – Advanced (Phân tích nâng cao, cảnh báo thông minh & cần đầu tư thêm dữ liệu)
6. **Smart Alerts dựa trên thống kê (Z-score Volume Spike, Early SLA Breach Risk, Overload Hint)**:
   - *Lý do:* Có thể triển khai từng phần sau khi API tổng hợp P0/P1 ổn định và hệ thống tích lũy đủ mật độ dữ liệu thực tế (>30 ngày vận hành liên tục) để ngưỡng thống kê không bị cảnh báo giả (false positive).
7. **Nâng cấp Schema Lịch sử & Phân loại (`report_status_history`, `category`, `zone_id`) + Dự báo chuỗi thời gian**:
   - *Lý do:* Cần thay đổi Database và cập nhật luồng ghi Backend (`completeReport`, `updateReportStatus`, `accept` delegation) để bảo toàn lịch sử đa vòng xử lý trước khi làm các phân tích dự báo tái phát hay dự báo theo học kỳ/khu vực.

---

## VII. Đánh giá tính khả thi

| Dashboard / Tính năng | Dữ liệu hiện có | Cần bổ sung API | Cần thay đổi DB | Độ phức tạp | Ưu tiên |
|---|---|---|---|---|---|
| **1. Executive System Health & Early Warning (`AdminHomeScreen`)** | Đầy đủ (`reports`, `users`, `account_lock_requests`) | Có (Mở rộng `GET /admin/home/overview` + endpoint/field `pulse7Days`) | Không bắt buộc *(khuyến nghị thêm index trên `reports(status, created_at)` & `reports(resolved_at)`)* | Trung bình – Thấp | **P0** |
| **2. Operational & Quality Analytics (`ReportDashboardScreen`)** | Có thể tính toán từ `reports` *(lưu ý mất lịch sử trước reopen do chưa có audit status)* | Có (Mở rộng `GET /admin/reports/statistics` hỗ trợ filter ngày & trả lead/cycle time, aging, rating; chuẩn hóa `/trend` dùng `TrendBucketHelper`) | Không bắt buộc cho v1 *(khuyến nghị thêm `report_status_history` cho v2)* | Trung bình | **P0** |
| **3. Staff Performance & Delegation (`StaffManagementScreen`)** | Đầy đủ (`reports`, `users`, `positions`, `report_delegations`) | Có (Mở rộng `GET /admin/staffs/statistics` thêm severity workload, rating/staff, full table, `delegationSummary`, `byPosition`) | Không | Trung bình | **P1** |
| **4. Spatial Hotspot & Risk Panel (`AdminMapScreen`)** | Đầy đủ (`latitude`, `longitude`, `createdAt`, `address`, `H3Core` có sẵn) | Có (Thêm `GET /admin/reports/spatial-analytics` tính top H3 cells & risk score theo timeframe) | Không *(trừ khi muốn bổ sung `zone_id` chuẩn hóa)* | Trung bình – Cao | **P1** |
| **5. User Engagement & Lock Governance (`UserManagementScreen` & `AdminBoardScreen`)** | Đủ cho hành vi tạo phản ánh/đánh giá/khóa *(thiếu DAU/MAU do không log login)* | Có (Mở rộng `GET /admin/users/statistics`, thêm filter `status` cho `/admin/users`, thêm breakdown cho `lock-requests`) | Không *(trừ khi muốn thêm `user_login_logs`)* | Thấp – Trung bình | **P1** |
| **6. Statistical Smart Alerts (Z-score Spike, SLA At-Risk, Overload Hint)** | Có thể tính toán trên nền dữ liệu 30–60 ngày | Có (Logic tính ngưỡng/cờ cảnh báo tại Backend Service) | Không | Trung bình | **P2** |
| **7. Predictive Forecasting & Rehandling History** | Chưa đầy đủ (thiếu `report_status_history`, thiếu `category`, cần >6 tháng dữ liệu chuỗi thời gian) | Có (API dự báo riêng + ghi nhận lịch sử chuyển trạng thái) | **Có** (Thêm bảng `report_status_history`, cột `category`, `zone_id`) | Cao | **P2** |
| **8. Financial Analytics Dashboard** | **Không có** (đã bị drop trong `DataInitializer.java`) | N/A | N/A | N/A | **Loại trừ** |

---

## VIII. Kết luận và lộ trình đề xuất

### 8.1. Tổng kết định hướng triển khai

1. **Những Dashboard nên triển khai trước (P0):**
   - Nâng cấp `ReportDashboardScreen` thành **Operational & Quality Analytics Dashboard** (bổ sung Lead Time, Cycle Time, Backlog Aging, luồng Inflow/Outflow/Rejected, và chất lượng đánh giá Rating/Rehandling) kết hợp loại bỏ sự trùng lặp của `/report-list`.
   - Nâng cấp `AdminHomeScreen` thành **Executive System Health & Early Warning** (Action Center Banner + KPI có delta + 7-Day Pulse).
2. **Những Dashboard nên triển khai sau (P1):**
   - Nâng cấp `StaffManagementScreen` (trọng số mức độ phức tạp `severity`, rating/rehandling theo nhân viên, và Delegation Analytics từ `report_delegations`).
   - Bổ sung **Spatial Hotspot & Risk Analytics Panel** ngay trên `AdminMapScreen` (tận dụng trực tiếp `H3Core` + tính năng `fly_to` sẵn có).
   - Hoàn thiện `UserManagementScreen` (trạng thái active/blocked, ẩn danh vs công khai, tỷ lệ review, Top Contributors theo kỳ) và breakdown kết quả biểu quyết ở `AdminBoardScreen`.
3. **Những dữ liệu cần bổ sung trong Database để mở khóa phân tích nâng cao (P2):**
   - **Bảng `report_status_history`** (`report_id`, `from_status`, `to_status`, `actor_id`, `assigned_staff_id`, `note`, `created_at`): Khắc phục triệt để tình trạng mất dữ liệu khi `reopen` (hiện đang ghi đè `resolvedAt`, `rating`, `isReviewResolved`) hoặc khi `delegation` (ghi đè `assignedAt`).
   - **Phân loại sự cố (`category`) & Khu vực chuẩn hóa (`zone_id` / `building_id`)** trên bảng `reports`: Giúp thống kê đúng loại hạ tầng hư hỏng và phân tích theo tòa nhà/khuôn viên trường học thay vì chỉ dựa vào địa chỉ text tự do.
   - *(Tùy chọn nếu cần đo mức độ sử dụng app)*: Bảng lưu lượt truy cập/đăng nhập (`user_activity_logs`) hoặc lượt đọc bản tin (`news_reads`).

### 8.2. Lộ trình triển khai đề xuất theo 3 giai đoạn

- **Giai đoạn 1 — Chuẩn hóa Backend & Nâng cấp P0 (Vận hành lõi):**
  - Chuẩn hóa `GET /admin/reports/trend` bằng `TrendBucketHelper` (zero-fill + đa chuỗi Created/Resolved/Rejected).
  - Mở rộng `GET /admin/reports/statistics` (hỗ trợ lọc khoảng ngày + bổ sung Lead Time, Cycle Time, Backlog Aging, Rating/Review stats) và `GET /admin/home/overview` (Action Center counts + 7-Day Pulse).
  - Cập nhật UI `AdminHomeScreen` và `ReportDashboardScreen` (dùng lại thư viện `fl_chart` và các shared widgets `KpiCard`, `TrendLineChart`, `ChartCard` sẵn có; đảm bảo 100% Light/Dark mode và L10n `app_vi.arb`/`app_en.arb`).
- **Giai đoạn 2 — Mở rộng chiều sâu Nhân sự, Không gian & Cộng đồng (P1):**
  - Mở rộng `StaffStatisticsResponse` (severity-weighted workload, rating & rehandling per staff, `ReportDelegation` summary, `Position` breakdown) và cập nhật `StaffManagementScreen`.
  - Xây dựng `GET /admin/reports/spatial-analytics` tận dụng `H3Core` + tích hợp Side Panel/Bottom Sheet tương tác `fly_to` trên `AdminMapScreen`.
  - Bổ sung bộ lọc/chỉ số còn thiếu cho `UserManagementScreen` và `LockRequestsTab`.
- **Giai đoạn 3 — Nền tảng Dữ liệu Lịch sử & Smart Analytics (P2):**
  - Thiết kế và triển khai bảng `report_status_history` (+ tùy chọn `category`, `zone_id`) để bảo toàn toàn bộ vòng đời xử lý.
  - Bổ sung các cờ cảnh báo thống kê sớm (Z-score volume spike, SLA At-Risk, nhân viên quá tải, điểm nóng tăng nhanh) và gợi ý tải nhẹ khi phân công.
  - Khi dữ liệu tích lũy đủ dài ($\ge 3\text{--}6$ tháng liên tục), triển khai mô hình dự báo xu hướng theo mùa vụ (Seasonal Smoothing) kèm dải tin cậy rõ ràng.
