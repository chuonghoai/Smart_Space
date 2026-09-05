---
name: smp-createTestCase
description: >-
  Đọc implementation thực tế và tạo test cases cho feature.
---

# smp-createTestCase

Mục đích: Đọc implementation thực tế và tạo test cases cho feature.

## Quy trình thực hiện (Workflow)

### Step 1 — Gather context
Đọc Requirement + Existing Code + Business Logic + Architecture + Error Handling.
**Ràng buộc:** KHÔNG được chỉ dựa vào requirement. Phải dựa trên code thực tế đã viết.

### Step 2 — Determine test coverage
Tạo Test Case bao phủ các trường hợp sau (chọn lọc cho phù hợp với feature, không máy móc tạo tất cả nếu không liên quan):
- Happy Path
- Negative Case
- Boundary
- Validation
- Permission
- Authentication
- Network Error / API Error
- Empty State / Loading State
- Concurrency
- Regression

### Step 3 — Generate Test Cases
Trình bày các test cases rõ ràng với input, expected output, và setup conditions.
