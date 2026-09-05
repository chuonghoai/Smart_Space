---
name: smp-reviewSecurityPerformance
description: >-
  Review security, safety, performance và quality của branch được chỉ định so với dev.
---

# smp-reviewSecurityPerformance

Mục đích: Review security, safety, performance và quality của branch được chỉ định so với `dev`.
Nếu user không chỉ định branch, sử dụng current branch.

## Dependencies
- [Shared Architecture Rules](../rules/shared-architecture-rules.md)
- [Shared Reporting Rules](../rules/shared-reporting-rules.md)

## Quy trình thực hiện (Workflow)

### Step 1 — Compare
So sánh target branch vs `dev`. Xác định toàn bộ code target branch có nhưng `dev` không có.

### Step 2 — Security Review
Kiểm tra các khía cạnh:
- **Authentication:** Token, session, refresh token, flow.
- **Authorization:** Permission, role, access control, privilege escalation.
- **API Security:** Rate limiting, validation, sanitization, replay risk, abuse.
- **Cryptography:** Hashing, encryption, signing, random generation. Đánh giá thuật toán có phù hợp không (KHÔNG mặc định SHA là encryption).
- **Secrets:** API key, secret, token, password. **KHÔNG ĐƯỢC hard-code.**
- **Data:** Sensitive data, local storage, logging, API response.
- **Mobile Security:** Deep link, WebView, permission, network security, local data.

### Step 3 — Performance Review
- **App:** Unnecessary rebuild/API calls, memory, image loading, list rendering, startup.
- **UX:** Flow có quá dài? Loading state, feedback, error recovery, empty state, responsiveness. (Phải dựa trên requirement, `design.md`, tính nhất quán. Không dựa trên sở thích cá nhân).
- **API:** N+1, pagination, response size, caching, timeout, retry, rate limiting.
- **Backend:** Database query, indexing, transaction, concurrency, memory, CPU.

### Output
Tạo báo cáo chi tiết về Security & Performance, phân loại theo Reporting Rules (BLOCKER, HIGH, v.v.).
