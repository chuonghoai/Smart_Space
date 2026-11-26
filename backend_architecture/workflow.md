# Development Workflow (API Lifecycle)

Tài liệu này hướng dẫn các bước tiêu chuẩn để tạo mới một API hoặc sửa chữa logic trong hệ thống Backend.

## 1. Quy trình tạo mới API

### Bước 1: Khởi tạo Request/Response DTO
- Đặt tại package: `com.vn.smart_space.dto.request` và `com.vn.smart_space.dto.response`.
- Định nghĩa các thuộc tính cần thiết, sử dụng Data Annotation của Lombok (`@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`).
- Thêm Validation Annotations cho các trường đầu vào (ví dụ: `@NotBlank`, `@Size`, `@Email`).

### Bước 2: Khởi tạo/Cập nhật Repository
- Đảm bảo Repository có sẵn các hàm truy vấn cần thiết (ví dụ: `findByEmail`, `existsByPhone`).
- Nếu cần truy vấn phức tạp, sử dụng `@Query`.

### Bước 3: Triển khai Business Logic ở Service
- Viết logic vào class `*ServiceImpl` implement Interface tương ứng.
- Đánh dấu `@Transactional` ở đầu method nếu có thay đổi DB (Insert/Update/Delete).
- Thực hiện logic: kiểm tra dữ liệu, ném ra các lỗi như `BadRequestException` hoặc `ResourceNotFoundException`.
- Tạo mới Model và lưu vào Repository.

### Bước 4: Tạo Controller Endpoint
- Đặt tại package `com.vn.smart_space.controller.*`.
- Thêm Endpoint với chuẩn RESTful (`@PostMapping`, `@GetMapping`, v.v).
- Tham số truyền vào phải bọc bởi `@RequestBody @Valid` (đối với POST/PUT) hoặc `@RequestParam`/`@PathVariable` (đối với GET/DELETE).
- Extract User Info bằng `@AuthenticationPrincipal Jwt jwt` nếu API yêu cầu xác thực.
- Gọi Service và trả về `ResponseEntity.ok(ApiResponse.success("Message", data))`.

## 2. Quy trình xử lý lỗi và Fix Bug

Khi gặp bug, Agent/Dev không được phép đi đường tắt bằng cách gọi Repository từ Controller:
1. **Trace Controller:** Kiểm tra dữ liệu đầu vào (DTO) đã truyền đúng vào chưa.
2. **Trace Service:** Mọi tính toán và sai lệch (nếu có) thường nằm ở đây. Kiểm tra các exception được bắn ra.
3. **Trace Repository:** Kiểm tra câu lệnh query SQL xem có lấy nhầm dữ liệu hay không.

Hãy chắc chắn bạn đã đọc [Security & Performance Rules](security_and_performance.md) trước khi triển khai một tính năng mới.
