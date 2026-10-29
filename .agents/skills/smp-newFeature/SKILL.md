---
name: smp-newFeature
description: >-
  Tiếp nhận mô tả của user về một chức năng mới và xây dựng Implementation Plan trước khi triển khai.
  Skill này sẽ phân tích requirement, inspect codebase và tạo plan.
---

# smp-newFeature

Mục đích: Tiếp nhận mô tả chức năng mới và xây dựng Implementation Plan trước khi triển khai.

## Dependencies (Quy tắc phải tuân thủ)
- [Shared Workflow](../../rules/shared-workflow.md)
- [Shared Architecture Rules](../../rules/shared-architecture-rules.md)
- [Shared UI & Localization Rules](../../rules/shared-ui-l10n-rules.md)
- [Design Taste Skill](../design-taste-frontend/SKILL.md) (Bắt buộc đọc và áp dụng nếu tính năng có giao diện UI/Frontend)
- Khuyến nghị tham khảo: `app_architecture/architecture/push_notification_rules.md` (nếu liên quan đến Notification).

## Quy trình thực hiện (Workflow)

### Step 1 — Understand requirement
Đọc và phân tích toàn bộ mô tả chức năng user cung cấp.
Xác định:
- Mục tiêu, Actor
- User flow, Business flow
- Input / Output
- API cần sử dụng/tạo mới
- Database, UI (Dark/Light mode), State management (nếu liên quan). Nếu có UI, đối chiếu tín hiệu với [design-taste-frontend](../design-taste-frontend/SKILL.md) (Page kind, Vibe, Audience, Constraints).
- Validation, Error handling, Permission/Authentication, Edge cases
- Các text hiển thị cho người dùng (để chuẩn bị L10n key)

### Step 2 — Inspect existing code
Tìm các feature/module có liên quan.
**Ràng buộc:** Không được mặc định tạo code mới nếu đã tồn tại implementation có thể tái sử dụng.

### Step 3 — Inspect architecture
Đọc các architecture document liên quan (tuân thủ Shared Architecture Rules).

### Step 4 — Inspect Git history
Kiểm tra các commit gần đây liên quan đến module/feature tương tự để hiểu pattern, convention và bug/fix cũ.

### Step 5 — Create Implementation Plan
Tạo Implementation Plan chỉ rõ:
- File cần tạo, file cần sửa
- Class/function/component, API, Model/Entity cần thêm/sửa
- Flow dữ liệu, Architecture layer bị ảnh hưởng
- Phân tích Routing: Khi tạo chức năng/màn hình mới, MUST tuân thủ cấu trúc route 3 file chuẩn của dự án:
  1. `route_name.dart`: Định nghĩa đối tượng `AppRouteInfo` (path, nameKey, icon, isHiddenInSearch, priority) và thêm vào danh sách `allRoutes`.
  2. `router_path.dart`: Tạo getter lấy path tham chiếu từ `RouteName` (vd: `static String get feature => RouteName.feature.path;`).
  3. `app_router.dart`: Khai báo `GoRoute` map với màn hình tương ứng.
- Phân tích UI: MUST tuân thủ Dark/Light mode, màu sắc/token theo `app_architecture/design/design.md`. Nếu tính năng có tạo mới màn hình/UI, MUST áp dụng [design-taste-frontend](../design-taste-frontend/SKILL.md): đưa ra 1 dòng "Design Read", xác lập The Three Dials (`DESIGN_VARIANCE`, `MOTION_INTENSITY`, `VISUAL_DENSITY`), và tuân thủ Anti-Default Discipline (không dùng màu sắc/layout rập khuôn AI-slop).
- Phân tích L10n: MUST xác định các key L10n cần tạo mới hoặc tái sử dụng cho user-facing text.
- Phân tích Backend Notification & L10n: Khi triển khai hay sửa code trong backend, phải gọi đến cột `language` trong bảng `users` của database (`User.getLanguage()`) để biết người dùng đang chọn ngôn ngữ nào, sau đó trong các code gửi thông báo WebSocket hay Firebase (FCM) đều phải tuân thủ đúng quy tắc key ngôn ngữ L10n (`MessageSource` với `messages_vi.properties` / `messages_en.properties` để hỗ trợ đúng đa ngôn ngữ). Tuyệt đối không được hardcode chuỗi văn bản Tiếng Việt hay Tiếng Anh nào trong code gửi thông báo của backend.
- Test cần thêm, Risk, Dependency, Migration (nếu có)

**STOP CONDITION:** KHÔNG được viết code ngay nếu user chưa yêu cầu thực thi. Chỉ đưa ra plan và đợi XÁC NHẬN (Approval).
