---
name: smp-analyzeTask
description: >-
  Phân tích một task trước khi bắt đầu implementation.
  Không thực hiện thay đổi code, chỉ trả về phân tích. 
  Đặc biệt chú ý phân tích các yêu cầu liên quan đến UI, Dark/Light mode, và Localization.
---

# smp-analyzeTask

Mục đích: Phân tích một task trước khi bắt đầu implementation.

## Dependencies
- [Shared UI & Localization Rules](../../rules/shared-ui-l10n-rules.md)
- [Design Taste Skill](../design-taste-frontend/SKILL.md) (Đối chiếu khi task có phạm vi liên quan đến UI/Frontend)

## Quy trình thực hiện (Workflow)

### Step 1 — Analyze
Đọc yêu cầu task, phân tích trong ngữ cảnh của codebase hiện tại.
Xác định:
- Requirement
- Scope
- Affected Modules
- Affected Files
- Dependencies
- Architecture Impact
- UI & L10n Impact: Đánh giá xem task có tạo mới/chỉnh sửa UI không; đối chiếu quy chuẩn Dark/Light mode, Localization và các nguyên tắc thiết kế từ [design-taste-frontend](../design-taste-frontend/SKILL.md).
- Risk
- Unknowns
- Questions
- Implementation Recommendation

### Step 2 — Report
Trình bày kết quả phân tích theo các mục trên.
**Ràng buộc:** Skill này KHÔNG được phép tự viết code.
