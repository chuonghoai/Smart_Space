---
name: smp-cleanup
description: >-
  Kiểm tra workspace sau khi hoàn thành task và dọn dẹp các file rác, file debug.
---

# smp-cleanup

Mục đích: Kiểm tra workspace sau khi hoàn thành task.

## Dependencies
- [Shared Git Rules](../rules/shared-git-rules.md)

## Quy trình thực hiện (Workflow)

### Step 1 — Scan Workspace
Tìm các file có thể là rác:
- Temporary files
- Generated reports
- Debug files
- Unused artifacts
- Unnecessary logs
- Temporary scripts

### Step 2 — Verification
**Ràng buộc nghiêm ngặt:** 
- KHÔNG được xóa source code hoặc configuration nếu chưa xác định chắc chắn đó là file tạm.
- Trước khi xóa file không rõ mục đích, phải YÊU CẦU USER XÁC NHẬN.

### Step 3 — Cleanup
Tiến hành xóa file an toàn sau khi đã được xác nhận (nếu cần).
