---
name: smp-reviewPR
description: >-
  Workflow tổng hợp để review PR. Thực hiện functional, architecture, design, security và performance review. Chờ user approve trước khi merge và dọn dẹp.
---

# smp-reviewPR

Mục đích: Workflow tổng hợp và là Skill quan trọng nhất để quản lý vòng đời PR.

## Dependencies
- [smp-review-code](../smp-review-code/SKILL.md)
- [smp-reviewSecurityPerformance](../smp-reviewSecurityPerformance/SKILL.md)
- [Shared Git Rules](../../rules/shared-git-rules.md)
- [Shared Reporting Rules](../../rules/shared-reporting-rules.md)
- [Shared UI & Localization Rules](../../rules/shared-ui-l10n-rules.md)

## Quy trình thực hiện (Workflow)

### Step 1 — Branch comparison
So sánh branch được chỉ định với `dev`. Xác định: commits, files, additions, modifications, deletions.

### Step 2 — Understand implementation
Đọc code của branch để hiểu toàn bộ chức năng.

### Step 3 — Thực hiện `smp-review-code`
Đánh giá Functional, Architecture, Code Quality, Design.

### Step 4 — Thực hiện `smp-reviewSecurityPerformance`
Đánh giá Security và Performance. KHÔNG được bỏ qua bước này.

### Step 5 — Audit Report
Tạo PR Audit Report với format sau:
```markdown
# PR Audit Report
## 1. Branch Information
## 2. Scope of Changes
## 3. Functional Assessment
## 4. Architecture Assessment
## 5. Design Assessment
## 6. Security Assessment
## 7. Performance Assessment
## 8. Code Quality Assessment
## 9. Issues (Severity, File, Location, Problem, Why it matters, Recommendation)
## 10. Risk Assessment
## 11. Merge Recommendation
## 12. Required Fixes
```

### Step 6 — STOP (WAIT FOR USER ACCEPTANCE)
**Ràng buộc nghiêm ngặt:** Sau khi report hoàn thành, KHÔNG được merge.
Phải dừng và chờ user xác nhận. Chỉ khi user explicitly accept/approve mới được đi tiếp.

### Step 7 — Merge và Cleanup
Sau khi user xác nhận merge:
1. Merge branch vào `dev`.
2. Kiểm tra merge thành công.
3. Xác nhận working tree.
4. Xóa branch local.
5. Xóa branch remote.
6. Xác nhận branch đã thực sự bị xóa khỏi remote.
7. Checkout `dev`.
8. Pull/update `dev`.
9. Clean workspace.

**Lưu ý:** 
- KHÔNG xóa branch trước khi merge thành công. 
- KHÔNG xóa branch nếu merge thất bại. 
- KHÔNG xóa branch khác với branch được chỉ định.
