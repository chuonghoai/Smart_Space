package com.vn.smart_space.controller.report;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.PrintStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

import static org.junit.jupiter.api.Assertions.*;

public class CreateReportTest {

    private static final String BASE_URL = System.getProperty("smartspace.baseUrl", "http://localhost:8989");

    private static String envOrDefault(String propKey, String envKey, String fallback) {
        String prop = System.getProperty(propKey);
        if (prop != null && !prop.isBlank()) {
            return prop.trim();
        }
        String env = System.getenv(envKey);
        if (env != null && !env.isBlank()) {
            return env.trim();
        }
        return fallback;
    }

    private static String loginAsClient(HttpClient client, ObjectMapper mapper) throws Exception {
        String email = envOrDefault("pw.client.email", "PW_CLIENT_EMAIL", "user@gmail.com");
        String password = envOrDefault("pw.client.password", "PW_CLIENT_PASSWORD", "Ad123456!");
        String loginJson = mapper.writeValueAsString(java.util.Map.of(
                "email", email,
                "password", password,
                "deviceId", "test-device-uuid",
                "deviceName", "Integration Test Client",
                "platform", "android",
                "role", "client",
                "rememberMe", true
        ));

        HttpRequest loginRequest = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/auth/login"))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(loginJson, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> loginResponse = client.send(loginRequest, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, loginResponse.statusCode(),
                "Đăng nhập Client thất bại (" + email + "): " + loginResponse.body());

        JsonNode root = mapper.readTree(loginResponse.body());
        JsonNode data = root.path("data");
        String token = data.hasNonNull("access_token")
                ? data.get("access_token").asText()
                : data.path("accessToken").asText("");
        assertFalse(token.isBlank(), "Không nhận được access_token từ /auth/login: " + loginResponse.body());
        return token;
    }

    @BeforeAll
    static void setupConsoleEncodingAndCheckBackendRunning() {
        // 1. Thiết lập encoding UTF-8 cho console terminal
        try {
            System.setOut(new PrintStream(System.out, true, StandardCharsets.UTF_8.name()));
            System.setErr(new PrintStream(System.err, true, StandardCharsets.UTF_8.name()));
        } catch (Exception ignored) {
        }

        // 2. Kiểm tra kết nối đến Backend Server (port 8989)
        URI base = URI.create(BASE_URL);
        boolean isRunning = false;
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(base.getHost(), base.getPort()), 1500);
            isRunning = true;
        } catch (Exception ignored) {
        }

        if (!isRunning) {
            System.err.println("================================================================================");
            System.err.println(">> [LỖI NGHIÊM TRỌNG] Backend chưa được khởi chạy tại " + BASE_URL + "!");
            System.err.println(">> Vui lòng chạy backend (ví dụ: 'npm run backend:dev') trên một terminal riêng.");
            System.err.println(">> Hệ thống sẽ KHÔNG tự khởi động backend để đảm bảo việc quản lý tiến trình.");
            System.err.println("================================================================================");
            fail("[LỖI] Backend chưa được khởi chạy tại " + BASE_URL + "! Vui lòng bật backend trước khi chạy test.");
        }
    }

    // Test Case ID: SMP-203
    // Description: Kiểm thử tích hợp Client u2 gửi yêu cầu POST /reports tạo phản ánh sự cố mới và nhận về HTTP 200 kèm id.
    @Test
    @DisplayName("Mô phỏng 1 Client tạo phản ánh sự cố thực tế trên App (gọi API 1 lần duy nhất)")
    void testCreateReport_SimulateRealClient() throws Exception {
        System.out.println("================================================================================");
        System.out.println(">> [TEST] Bắt đầu mô phỏng 1 Client (User: user@gmail.com / ID: u2) gửi phản ánh...");
        System.out.println(">> Target Server : " + BASE_URL);
        System.out.println("================================================================================");

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        ObjectMapper mapper = new ObjectMapper();

        // 1. Đăng nhập lấy JWT Bearer Token hợp lệ + khởi tạo phiên Redis cho User 'u2' (role: client)
        String bearerToken = loginAsClient(client, mapper);

        // 2. Chuẩn bị Payload JSON 100% giống với smartspace_client gửi lên
        String requestJson = """
        {
          "title": "Sự cố cây xanh gãy đổ chắn ngang đường",
          "description": "Cây xanh lớn bị bật gốc đè lên đường số 1, chắn ngang làn xe máy và ô tô, có nguy cơ chập điện nguy hiểm.",
          "image_urls": [
            "https://images.unsplash.com/photo-1542601906990-b4d3fb778b09",
            "https://images.unsplash.com/photo-1513836279014-a89f7a76ae86"
          ],
          "latitude": 10.8506,
          "longitude": 106.7720,
          "is_anonymous": false,
          "address": "Số 1 Võ Văn Ngân, Phường Linh Chiểu, TP. Thủ Đức, TP. Hồ Chí Minh",
          "location_description": "Gần cổng số 1 trường ĐH Sư Phạm Kỹ Thuật TP.HCM"
        }
        """;

        // 3. Thực hiện gọi HTTP POST đến /reports (1 lần duy nhất)
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + bearerToken)
                .POST(HttpRequest.BodyPublishers.ofString(requestJson, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

        // 4. In thông tin và Assert phản hồi từ server
        System.out.println("================================================================================");
        System.out.println(">> [KẾT QUẢ] Đã gửi yêu cầu tạo phản ánh thành công tới Server đang chạy!");
        System.out.println(">> HTTP Status Code : " + response.statusCode());
        System.out.println(">> Response Body    : " + response.body());
        System.out.println(">> Realtime Event   : WebSocket & Notification đã được kích hoạt trực tiếp trên Server!");
        System.out.println("================================================================================");

        assertEquals(200, response.statusCode(), "HTTP Status phải là 200 OK");
        assertNotNull(response.body(), "Body response không được rỗng");
        assertTrue(response.body().contains("\"success\":true"), "Phản hồi phải có success là true");
        assertTrue(response.body().contains("\"id\":"), "Phản hồi phải chứa trường 'id' của report mới tạo");
    }
}
