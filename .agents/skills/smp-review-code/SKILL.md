---
name: smp-review-code
description: >-
  Review branch hiện tại so với branch dev. 
  Đánh giá functional, architecture, code quality, và design.
---

# smp-review-code

Mục đích: Review branch hiện tại so với `dev`.

## Dependencies
- [Shared Architecture Rules](../rules/shared-architecture-rules.md)
- [Shared Reporting Rules](../rules/shared-reporting-rules.md)
- UI/Design rules: `app_architecture/design/design.md`

## Quy trình thực hiện (Workflow)

### Step 1 — Xác định branch
- Current branch
- Target branch = `dev`

### Step 2 — Compare
So sánh branch hiện tại với `dev`. Xác định chính xác: files added, modified, deleted; commits khác nhau; code hiện tại mà `dev` không có. 
**Ràng buộc:** Không được chỉ review vài file ngẫu nhiên.

### Step 3 — Understand implementation
Đọc implementation của branch hiện tại để hiểu: chức năng, business flow, data flow, architecture, dependency.

### Step 4 — Check Architecture rules
Đọc kỹ các tài liệu kiến trúc.

### Step 5 — Review
Đánh giá trên 4 khía cạnh:
1. **Functional:** Requirement, happy path, edge case, error handling, loading/empty state, permission/auth.
2. **Architecture:** Đúng kiến trúc không? Sai layer? Duplicate logic? Bypass abstraction? Dependency sai chiều?
3. **Code Quality:** Readability, maintainability, naming, null safety, logging.
4. **Design (Nếu có UI):** Layout, navigation, interaction, consistency so với `design.md`.

### Output
Tạo review report với cấu trúc:
- Summary
- Changed Scope
- Functional Review
- Architecture Review
- Code Quality Review
- Design Review
- Issues (Gắn nhãn BLOCKER, HIGH, MEDIUM, LOW, INFO)
- Risk & Recommendation
