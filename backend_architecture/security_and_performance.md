# Security & Performance Rules

## 1. Authentication & Authorization
- **JWT (JSON Web Token):** Mọi request yêu cầu xác thực đều phải kiểm tra JWT Token. Backend cung cấp cả `AccessToken` (dùng để xác thực) và `RefreshToken` (dùng để gia hạn).
- **Session Management:** Refresh Token và các phiên đăng nhập đang active phải được quản lý trong Redis (hoặc bảng DB tuỳ cấu hình hiện hành, ví dụ `RefreshTokenSessionRepository`).
- **Blacklist:** Khi logout, AccessToken phải được đẩy vào Blacklist (lưu qua `InvalidatedTokenRepository` với thời gian sống - TTL bằng thời gian còn lại của token).

## 2. Secrets & Cryptography
- **Tuyệt đối KHÔNG hard-code:** Mọi thông tin nhạy cảm (Google Client ID, JWT Secret, Database Password, v.v) đều phải lấy từ biến môi trường (`.env` hoặc `application.properties`).
- **Hashing vs Encryption:**
  - Password **bắt buộc** phải được băm (hash) bằng `PasswordEncoder` (như BCrypt) trước khi lưu vào DB. KHÔNG bao giờ lưu cleartext.
  - Phân biệt rõ: Hashing là 1 chiều (mật khẩu). Encryption là 2 chiều (nếu cần giải mã).

## 3. Redis & Caching
- **OTP & Cooldown:** Mã OTP và các giới hạn gọi API (như "Gửi lại sau 60s") bắt buộc lưu trong Redis với TTL cố định. Điều này ngăn chặn abuse/spam.
  - Cấu trúc ví dụ: Key = `otp:register:email@example.com`, TTL = 5 phút. Key = `cooldown:otp:email@example.com`, TTL = 60 giây.
- **Session:** Redis được dùng để lưu trữ session truy cập nhanh, hỗ trợ chức năng "Đăng xuất khỏi các thiết bị khác".

## 4. Performance & Database
- Sử dụng `@Transactional` hợp lý.
- Tránh N+1 Query: Sử dụng `JOIN FETCH` trong JPQL hoặc `@EntityGraph` khi cần truy vấn dữ liệu quan hệ.
- Luôn giới hạn size của list trả về (Pagination) với những query có nguy cơ trả về lượng lớn dữ liệu.
