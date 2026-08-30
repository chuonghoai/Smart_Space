# Kiến trúc hệ thống (Architecture)

Project được thiết kế dựa trên kiến trúc phân lớp, tuân thủ nguyên tắc Dependency một chiều (Unidirectional Dependency Flow):

```text
UI (Mobile/Web)
 ↓
Controller
 ↓
Service
 ↓
Repository
 ↓
Data Source / API
```

Mục tiêu là mỗi layer có trách nhiệm riêng biệt nhưng vẫn phối hợp được với nhau:
- Không để Repository gọi ngược Controller.
- Không để Repository gọi UI.
- Không để Service gọi trực tiếp UI.
- Không để Service gọi ngược Controller.
- Không để Model chứa logic UI.

Nếu một tính năng yêu cầu ngoại lệ, nó phải tuân theo pattern hiện có của project.
