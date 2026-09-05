# API Rules (Layer Responsibilities)

## 1. Controller Layer
**Nhiệm vụ:** Là cửa ngõ giao tiếp HTTP.

**DO (Nên làm):**
- Định nghĩa các endpoint (GET, POST, PUT, DELETE).
- Parse request body thành DTO (Data Transfer Object).
- Validate input sử dụng `@Valid`.
- Extract các thông tin từ request (như IP Address qua `HttpServletRequest`, User ID qua `@AuthenticationPrincipal Jwt`).
- Gọi duy nhất 1 (hoặc rất ít) method của Service.
- Bọc kết quả trả về bằng `ResponseEntity<ApiResponse>`.

**DON'T (Tuyệt đối KHÔNG):**
- KHÔNG chứa Business Logic (logic nghiệp vụ).
- KHÔNG gọi trực tiếp Repository, DB hay Redis.
- KHÔNG ném ra Exception trực tiếp (Service sẽ làm việc này).

## 2. Service Layer
**Nhiệm vụ:** Nơi chứa toàn bộ Business Logic.

**DO:**
- Xử lý logic nghiệp vụ, tính toán.
- Giao tiếp với nhiều Repository (DB, Redis) để thực hiện một use-case hoàn chỉnh.
- Sử dụng `@Transactional` đối với các thao tác thay đổi dữ liệu (insert/update/delete) để đảm bảo tính toàn vẹn (rollback khi có lỗi).
- Ném ra các Exception tuỳ chỉnh (như `BadRequestException`, `UnauthorizedException`) để ControllerAdvice tự động map thành HTTP Status tương ứng.
- Phối hợp với các helper/service khác (như `IJwtService`, `IMailService`).

**DON'T:**
- KHÔNG thao tác trực tiếp với các object liên quan tới HTTP (như `HttpServletRequest`, `HttpServletResponse`) trong Service (phải truyền thông số từ Controller xuống).

## 3. Repository Layer
**Nhiệm vụ:** Thao tác trực tiếp với dữ liệu.

**DO:**
- Kế thừa `JpaRepository` hoặc sử dụng `StringRedisTemplate`.
- Định nghĩa các custom query (`@Query` hoặc Spring Data Query methods).

**DON'T:**
- KHÔNG xử lý business logic.
- KHÔNG ném HTTP Exception.

## 4. Duplicate Prevention Rules (Chống trùng lặp code)
Để tránh tình trạng tạo ra `ServiceA.validateUser()`, `ServiceB.validateUser()`:
- **Kiểm tra trước khi code:** Khi cần một logic, LUÔN search xem có Service nào đang làm việc tương tự không.
- **Tái sử dụng (Reuse):** Inject Service có sẵn (ví dụ: `IUserService`) thay vì viết lại logic vào Service hiện tại.
- **Shared Helpers:** Các logic không thuộc domain cụ thể (như tạo OTP, parse ngày tháng) phải được để trong package `utils` (ví dụ `OtpGenerator`).
