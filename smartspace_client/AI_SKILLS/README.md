# AI Skills cho SmartSpace Client

Thư mục này chứa toàn bộ quy tắc về architecture và convention bắt buộc đối với tất cả AI agents khi làm việc trên dự án này.

**QUAN TRỌNG:**
1. AI Agent BẮT BUỘC phải đọc các rule trong thư mục này trước khi triển khai hoặc sửa đổi code.
2. Tính năng **Login** (`lib/features/auth/...` và `lib/ui/.../auth/...`) được dùng làm **Reference Architecture**. Bạn phải tham khảo code thực tế của Login trước khi code.
3. Không over-engineering. Không tạo mới abstraction, service, repository, model nếu dự án đã có sẵn code có thể tái sử dụng.
4. Mọi quy tắc trong này được xây dựng dựa trên code thực tế đang được sử dụng trong dự án.

## Cấu trúc tài liệu:
- `architecture/`: Quy tắc về UI, Controller, Service, Repository, Model, và Dependency Flow.
- `localization/`: Quy tắc về đa ngôn ngữ (EN/VN).
- `navigation/`: Quy tắc về GoRouter.
- `feature-development/`: Quy trình phát triển tính năng mới và Definition of Done.
