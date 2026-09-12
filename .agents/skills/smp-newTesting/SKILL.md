---
name: smp-newTesting
description: >-
  Quy chuẩn tạo file test trong Backend (SmartSpace_Backend) để mô phỏng tương tác từ Client/Admin/Staff (Realtime & API Integration Test) và cấu hình lệnh chạy nhanh trong testapi.ps1.
---

# smp-newTesting

Mục đích: Quy định chuẩn hóa quy trình tạo file `*Test.java` trong Backend nhằm mô phỏng 100% hành vi thực tế của Client/Admin (kiểm thử luồng CSDL, WebSocket, FCM Notification) và đăng ký command runner vào `testapi.ps1`.

## Dependencies (Quy tắc phải tuân thủ)
- [Shared Workflow](../rules/shared-workflow.md)
- [Push Notification Architecture Rules](../../app_architecture/architecture/push_notification_rules.md)

---

## Quy trình thực hiện (Workflow)

### Step 1 — Xác định kịch bản kiểm thử (Test Scenario & Actor)
1. Xác định Controller, API Endpoint và phương thức cần mô phỏng (ví dụ: `ReportController.createReport`).
2. Xác định Actor thực hiện hành động:
   - **Client** (User thông thường): Cần `Jwt` chứa claim `userId`.
   - **Staff / Admin**: Cần `Jwt` với quyền hạn tương ứng.
   - **Anonymous / Guest**: Không kèm user hoặc cờ ẩn danh.
3. Thu thập định dạng Payload thực tế:
   - Đọc DTO của mobile/web app (`smartspace_client` hoặc `smartspace_staff`) để đảm bảo payload gửi trong test **100% giống với app thực tế** (bao gồm cả trường hợp null, chuỗi ảnh, tọa độ GPS, snake_case mapping).

---

### Step 2 — Tạo file Test Java trong Backend

1. **Vị trí file**: Đặt trong thư mục `SmartSpace_Backend/src/test/java/com/vn/smart_space/...` theo package tương ứng của Controller/Service (ví dụ: `com.vn.smart_space.controller.report.CreateReportTest`).
2. **Quy tắc Kiểm tra Backend Đang Chạy (Health Check)**:
   - **BẮT BUỘC** kiểm tra xem server backend (`http://localhost:8989`) đã được bật hay chưa trong `@BeforeAll`.
   - **TUYỆT ĐỐI KHÔNG** dùng `@SpringBootTest` để tự khởi động một Spring context phụ bên trong test runner. Việc này giúp test chạy siêu nhanh (< 1s), không gây xung đột DB và giúp developer dễ dàng kiểm soát terminal chạy `npm run backend:dev`.
   - Nếu backend chưa chạy, ném lỗi rõ ràng và dừng ngay lập tức.
3. **Quy tắc Thực thi Test**:
   - Chỉ tạo **1 test method duy nhất** cho 1 nghiệp vụ mô phỏng, gọi API đúng **1 lần duy nhất**.
   - Chuẩn bị `Jwt` bearer token hợp lệ với đầy đủ claims (`userId`, `scope`, `tokenType: access`, `deviceId`) được ký bằng `jwt.signerKey`.
   - Gửi request qua `java.net.http.HttpClient` với payload JSON giống 100% Client/App.
   - Assert HTTP Status 200 OK và body phản hồi.

**Mẫu code chuẩn:**
```java
public class ExampleActionTest {

    private static final String BASE_URL = "http://localhost:8989";
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";

    @BeforeAll
    static void setupAndCheckServerRunning() {
        try {
            System.setOut(new PrintStream(System.out, true, StandardCharsets.UTF_8.name()));
            System.setErr(new PrintStream(System.err, true, StandardCharsets.UTF_8.name()));
        } catch (Exception ignored) {}

        // Kiểm tra kết nối Backend
        boolean isRunning = false;
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("localhost", 8989), 1500);
            isRunning = true;
        } catch (Exception ignored) {}

        if (!isRunning) {
            fail("[LỖI] Backend chưa được khởi chạy tại " + BASE_URL + "! Vui lòng chạy backend (npm run backend:dev) trước khi test.");
        }
    }

    @Test
    @DisplayName("Mô phỏng 1 Client thực hiện hành động ... (gọi API 1 lần duy nhất)")
    void testAction_SimulateClient() throws Exception {
        // 1. Tạo JWT Bearer Token hợp lệ
        Date issueTime = new Date();
        Date expiryTime = new Date(System.currentTimeMillis() + 3600_000);
        JWSHeader header = new JWSHeader(JWSAlgorithm.HS512);
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .subject("user@gmail.com")
                .issuer("smartspace.vn")
                .issueTime(issueTime)
                .expirationTime(expiryTime)
                .jwtID(UUID.randomUUID().toString())
                .claim("scope", "client")
                .claim("userId", "u2")
                .claim("deviceId", "test-device-id")
                .claim("tokenType", "access")
                .build();

        SignedJWT signedJWT = new SignedJWT(header, claims);
        signedJWT.sign(new MACSigner(SIGNER_KEY.getBytes(StandardCharsets.UTF_8)));
        String bearerToken = signedJWT.serialize();

        // 2. Gửi Request qua HttpClient
        String jsonPayload = """
        {
          "field": "value"
        }
        """;

        HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/endpoint"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + bearerToken)
                .POST(HttpRequest.BodyPublishers.ofString(jsonPayload, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

        // 3. Assert
        assertEquals(200, response.statusCode());
        assertTrue(response.body().contains("system.success"));
    }
}
```

---

### Step 3 — Đăng ký lệnh vào testapi.ps1

Mở file `testapi.ps1` ở cấp cao nhất của project và thêm định nghĩa vào bảng `$TestRegistry`:

```powershell
$TestRegistry = @{
    "CreateReport" = @{
        TestClass   = "com.vn.smart_space.controller.report.CreateReportTest"
        Description = "Mô phỏng 1 Client tạo phản ánh sự cố thực tế (100% giống app) & kích hoạt realtime websocket/FCM"
    }
    # Thêm lệnh mới tại đây:
    "<CommandName>" = @{
        TestClass   = "<Full.Package.Path.To.YourTestClass>"
        Description = "<Mô tả ngắn gọn kịch bản và mục đích>"
    }
}
```

**Quy tắc đặt tên lệnh (`<CommandName>`):**
- Đặt tên theo dạng `PascalCase`, ngắn gọn, thể hiện rõ hành vi (ví dụ: `CreateReport`, `UpdateReportStatus`, `SendOtp`, `FeedbackReport`).

---

### Step 4 — Kiểm tra và xác minh (Verification)

1. Kiểm tra danh sách lệnh:
   ```powershell
   .\testapi.ps1 help
   ```
2. Chạy thử lệnh test vừa đăng ký:
   ```powershell
   .\testapi.ps1 <CommandName>
   ```
3. Xác nhận test chạy thành công (`exitCode == 0`), log hiển thị chi tiết và sự kiện realtime được kích hoạt trên hệ thống.

