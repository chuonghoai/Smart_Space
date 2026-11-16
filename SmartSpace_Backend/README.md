# SmartSpace Backend

Backend service cho hệ thống SmartSpace (Java 17, Spring Boot 4, Spring Data Redis / Lettuce, MySQL).

## 1. Cấu hình Redis / Valkey (Local Docker & Aiven Cloud)

Hệ thống sử dụng duy nhất `LettuceConnectionFactory` và `StringRedisTemplate` trong `RedisConfig`, kết nối thông qua biến môi trường duy nhất `REDIS_URL` (`spring.data.redis.url`):

- **Development (Local Docker)**: Dùng `REDIS_URL=redis://localhost:6379` (giá trị mặc định trong `application.yaml` và `.env.example`) để kết nối Redis Docker trong `docker-compose.yaml`.
- **Production (Aiven for Valkey)**: Đặt `REDIS_URL` bằng Service URI từ Aiven (`rediss://` hoặc `valkeys://`), backend tự động bật TLS, giữ nguyên xác thực chứng chỉ SSL/TLS mặc định của JVM, cấu hình reconnect/timeouts và shutdown gọn gàng qua `LettuceConnectionFactory`.

### Chạy Redis Docker cho môi trường Development

```bash
cd SmartSpace_Backend
docker compose up -d redis
```

Sao chép `.env.example` thành `.env` và giữ `REDIS_URL=redis://localhost:6379` khi chạy local:

```bash
cp .env.example .env
```

---

## 2. Hướng dẫn triển khai Aiven for Valkey cho Production (Render)

### Bước 1: Tạo dịch vụ Aiven for Valkey
1. Đăng nhập vào Aiven Console và chọn **Create service**.
2. Chọn **Valkey** (tương thích giao thức Redis OSS).
3. Chọn Cloud provider/region gần Render region của backend nhất để giảm độ trễ.
4. Chọn plan phù hợp và nhấn **Create service**, đợi trạng thái chuyển sang **Running**.

### Bước 2: Lấy Connection URI từ Aiven
1. Mở dịch vụ Valkey vừa tạo -> tab **Overview**.
2. Sao chép giá trị **Service URI** (hoặc **Redis URI**), có dạng:
   ```text
   rediss://default:<password>@<host>.aivencloud.com:<port>
   ```
3. Đảm bảo giao thức là `rediss://` (hoặc `valkeys://`) để luôn bật TLS.

### Bước 3: Cấu hình biến môi trường trên Render
1. Mở service Backend trên **Render Dashboard** -> **Environment**.
2. Thêm biến môi trường:
   - **Key**: `REDIS_URL`
   - **Value**: dán nguyên Service URI từ Aiven (không bọc thêm dấu ngoặc kép).
3. Toàn bộ cấu hình Redis của backend chỉ sử dụng duy nhất biến `REDIS_URL` (`spring.data.redis.url`).
4. **Lưu ý về TLS Certificate**:
   - Các dịch vụ Aiven for Valkey mới sử dụng **Let's Encrypt CA** làm CA mặc định, được JVM (`cacerts`) tin cậy sẵn — backend sẽ kết nối `rediss://` mà không cần thêm cấu hình.
   - Nếu cluster Aiven của bạn là cluster cũ dùng **Aiven Project CA (`ca.pem`)**, cần import `ca.pem` vào truststore (`keytool -importcert`) và truyền `-Djavax.net.ssl.trustStore=...` qua `JAVA_TOOL_OPTIONS` trên Render. Tuyệt đối **không** tắt TLS verification.

### Bước 4: Redeploy Backend
1. Nhấn **Manual Deploy -> Deploy latest commit** (hoặc lưu Environment Variables để Render tự redeploy).

### Bước 5: Kiểm tra kết nối Redis sau khi deploy
1. Xem **Render Logs** khi ứng dụng khởi động, xác nhận xuất hiện log an toàn (không chứa mật khẩu hay URI):
   ```text
   Initializing Redis connection factory [tls=true, host=<your-host>, port=<your-port>, database=0]
   Redis connection ready [tls=true, host=<your-host>, port=<your-port>, ping=PONG]
   ```
2. Kiểm tra nhanh các chức năng sử dụng Redis:
   - Đăng nhập / làm mới token / đăng xuất (`RefreshTokenSession`, `InvalidatedToken`)
   - Quên mật khẩu / OTP & cooldown
   - Trạng thái online chat (`ChatPresenceService`)
   - Dữ liệu mật độ báo cáo GEO/ZSet/Hash (`ReportDensityServiceImpl`)
