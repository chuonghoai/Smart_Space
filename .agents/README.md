# AI Agent Skills System

Hệ thống Skills này được thiết kế để chuẩn hóa cách AI Agent làm việc trong dự án SmartSpace, quản lý các quy trình phát triển, review code và quản lý Pull Request (PR) một cách an toàn và tuân thủ chặt chẽ kiến trúc dự án.

## Source of Truth (Nguồn chân lý kiến trúc)
Mọi thay đổi do AI Agent thực hiện phải tuân thủ:
- `app_architecture/`
- `backend_architecture/`
- `app_architecture/design/design.md`

## Danh sách Skills (Commands)

| Command | Purpose | Input | Can modify code | Can modify Git | Requires approval |
|---------|---------|-------|-----------------|----------------|-------------------|
| `/smp-newFeature` | Phân tích và lập kế hoạch tính năng mới | Mô tả tính năng | Có (khi được phép) | Không | **Có** (cho Implementation Plan) |
| `/smp-fixbug` | Phân tích root cause và lập kế hoạch sửa lỗi | Mô tả bug | Có (khi được phép) | Không | **Có** (cho Implementation Plan) |
| `/smp-review-code` | Review code branch hiện tại so với dev | Không/Branch name | Không | Không | Không |
| `/smp-createPR` | Push code và tạo PR | Không | Không | Có (push) | Không (chỉ tạo URL PR) |
| `/smp-reviewSecurityPerformance`| Đánh giá bảo mật và hiệu năng của code mới | Branch name | Không | Không | Không |
| `/smp-reviewPR` | **Tổng hợp:** Review toàn diện và Merge PR | Branch name | Không | Có (merge, xóa branch) | **CÓ** (trước khi Merge) |
| `/smp-analyzeTask`| Phân tích scope, risk của một task | Mô tả task | Không | Không | Không |
| `/smp-createTestCase`| Đọc code để tạo Test Cases | Không | Không | Không | Không |
| `/smp-cleanup` | Dọn dẹp workspace sau khi xong task | Không | Không (chỉ xóa rác) | Không | **Có** (trước khi xóa file) |

## Dependency & Workflow

```text
/smp-reviewPR
    ├── /smp-review-code
    │   ├── Shared Architecture Rules
    │   └── Shared Reporting Rules
    ├── /smp-reviewSecurityPerformance
    │   ├── Shared Architecture Rules
    │   └── Shared Reporting Rules
    └── Shared Git Rules (Xử lý Merge & Xóa branch)

/smp-newFeature & /smp-fixbug
    ├── Shared Workflow
    └── Shared Architecture Rules
```

## Các thao tác cần Confirmation (Sự cho phép của User)
1. **Thực thi code mới/Sửa code:** Agent phải đưa ra Plan trước, user đồng ý mới được code.
2. **Merge PR:** Phải chờ user đọc xong Audit Report và gõ đồng ý mới được merge.
3. **Xóa file:** Trong lúc cleanup, nếu không chắc chắn 100% là file rác thì phải hỏi ý kiến user.
4. **Bypass Architecture:** Bất kỳ phương án nào đi ngược lại với kiến trúc chuẩn đều phải xin phép.
