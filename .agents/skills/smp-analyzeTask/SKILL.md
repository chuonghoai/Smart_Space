---
name: smp-analyzeTask
description: >-
  Phân tích một task trước khi bắt đầu implementation.
  Không thực hiện thay đổi code, chỉ trả về phân tích. 
  Đặc biệt chú ý phân tích các yêu cầu liên quan đến UI, Dark/Light mode, và Localization.
---

# smp-analyzeTask

Mục đích: Phân tích một task trước khi bắt đầu implementation.

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
- Risk
- Unknowns
- Questions
- Implementation Recommendation

### Step 2 — Report
Trình bày kết quả phân tích theo các mục trên.
**Ràng buộc:** Skill này KHÔNG được phép tự viết code.
