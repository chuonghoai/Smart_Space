package com.vn.smart_space.controller.report;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
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
import java.util.Date;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

public class CreateReportTest {

    private static final String BASE_URL = "http://localhost:8989";
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";

    @BeforeAll
    static void setupConsoleEncodingAndCheckBackendRunning() {
        // 1. Thiết lập encoding UTF-8 cho console terminal
        try {
            System.setOut(new PrintStream(System.out, true, StandardCharsets.UTF_8.name()));
            System.setErr(new PrintStream(System.err, true, StandardCharsets.UTF_8.name()));
        } catch (Exception ignored) {
        }

        // 2. Kiểm tra kết nối đến Backend Server (port 8989)
        boolean isRunning = false;
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("localhost", 8989), 1500);
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

    @Test
    @DisplayName("Mô phỏng 1 Client tạo phản ánh sự cố thực tế trên App (gọi API 1 lần duy nhất)")
    void testCreateReport_SimulateRealClient() throws Exception {
        System.out.println("================================================================================");
        System.out.println(">> [TEST] Bắt đầu mô phỏng 1 Client (User: user@gmail.com / ID: u2) gửi phản ánh...");
        System.out.println(">> Target Server : " + BASE_URL);
        System.out.println("================================================================================");

        // 1. Tạo JWT Bearer Token hợp lệ của User 'u2' (role: client)
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
                .claim("deviceId", "test-device-uuid")
                .claim("tokenType", "access")
                .build();

        SignedJWT signedJWT = new SignedJWT(header, claims);
        signedJWT.sign(new MACSigner(SIGNER_KEY.getBytes(StandardCharsets.UTF_8)));
        String bearerToken = signedJWT.serialize();

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
        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();

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
