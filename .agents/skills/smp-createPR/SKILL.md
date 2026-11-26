---
name: smp-createPR
description: >-
  Chuẩn bị code hiện tại và tạo Pull Request từ branch hiện tại vào dev.
---

# smp-createPR

Mục đích: Chuẩn bị code hiện tại và tạo Pull Request từ branch hiện tại -> `dev`.

## Dependencies
- [Shared Git Rules](../rules/shared-git-rules.md)

## Quy trình thực hiện (Workflow)

### Step 1 — Check status
Kiểm tra: current branch, working tree, staged/unstaged changes, untracked files, commits chưa push.

### Step 2 — Scope validation
Xác định rõ phạm vi thay đổi.
**Ràng buộc:** KHÔNG được tự ý commit các file không liên quan.

### Step 3 — Push
Push code lên remote. 
**Lưu ý:** Trước các thao tác có khả năng thay đổi remote repository, phải kiểm tra trạng thái và đảm bảo branch đúng.

### Step 4 — Create PR URL
Tạo GitHub Pull Request URL với: `base = dev`, `head = current branch`.
URL phải được tạo sao cho user có thể click mở trực tiếp trên trình duyệt.

### Step 5 — PR Body Template
Nếu có thể prefill, hãy điền sẵn nội dung theo template sau:
```markdown
## Summary

## Changes

## Implementation

## Testing

## Risk

## Checklist
- [ ] Tested
- [ ] Architecture compliant
- [ ] No unrelated changes
- [ ] Error handling verified
```

**STOP CONDITION:** KHÔNG ĐƯỢC TỰ MERGE PR.
