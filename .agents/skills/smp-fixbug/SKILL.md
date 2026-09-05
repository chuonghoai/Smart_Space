---
name: smp-fixbug
description: >-
  Phân tích bug và tạo Implementation Plan để sửa bug.
  Truy vết root cause và đưa ra phương án sửa lỗi an toàn.
---

# smp-fixbug

Mục đích: Phân tích bug và tạo Implementation Plan để sửa bug.

## Dependencies
- [Shared Workflow](../rules/shared-workflow.md)
- [Shared Architecture Rules](../rules/shared-architecture-rules.md)

## Quy trình thực hiện (Workflow)

### Step 1 — Understand bug
Đọc kỹ bug description. Xác định:
- Expected behavior vs Actual behavior
- Reproduction condition
- Affected platform & module
- Severity

### Step 2 — Trace
Tìm tất cả code liên quan. KHÔNG chỉ tìm file có tên giống bug.
Phải trace flow: `UI -> state -> business logic -> repository/service -> API -> backend -> database` (khi phù hợp).

### Step 3 — Inspect Git history
Kiểm tra commit gần nhất, commit thay đổi behavior, commit liên quan feature, commit fix bug tương tự (dùng blame nếu cần).

### Step 4 — Determine Root Cause
Xác định nguyên nhân cốt lõi. Phân biệt rõ ràng giữa "Symptom" (triệu chứng) và "Root Cause" (nguyên nhân gốc rễ).

### Step 5 — Create Implementation Plan
Plan phải bao gồm:
- Root cause
- Affected files & Affected flow
- Proposed fix
- Side effects & Regression risks
- Test cases cần kiểm tra

**STOP CONDITION:** KHÔNG được sửa code ngay nếu user chỉ yêu cầu tạo plan.
