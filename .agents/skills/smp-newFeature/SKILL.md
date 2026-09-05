---
name: smp-newFeature
description: >-
  Tiếp nhận mô tả của user về một chức năng mới và xây dựng Implementation Plan trước khi triển khai.
  Skill này sẽ phân tích requirement, inspect codebase và tạo plan.
---

# smp-newFeature

Mục đích: Tiếp nhận mô tả chức năng mới và xây dựng Implementation Plan trước khi triển khai.

## Dependencies (Quy tắc phải tuân thủ)
- [Shared Workflow](../rules/shared-workflow.md)
- [Shared Architecture Rules](../rules/shared-architecture-rules.md)
- [Shared UI & Localization Rules](../rules/shared-ui-l10n-rules.md)

## Quy trình thực hiện (Workflow)

### Step 1 — Understand requirement
Đọc và phân tích toàn bộ mô tả chức năng user cung cấp.
Xác định:
- Mục tiêu, Actor
- User flow, Business flow
- Input / Output
- API cần sử dụng/tạo mới
- Database, UI (Dark/Light mode), State management (nếu liên quan)
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
- Phân tích UI: MUST tuân thủ Dark/Light mode, màu sắc/token cần sử dụng.
- Phân tích L10n: MUST xác định các key L10n cần tạo mới hoặc tái sử dụng cho user-facing text.
- Test cần thêm, Risk, Dependency, Migration (nếu có)

**STOP CONDITION:** KHÔNG được viết code ngay nếu user chưa yêu cầu thực thi. Chỉ đưa ra plan và đợi XÁC NHẬN (Approval).
