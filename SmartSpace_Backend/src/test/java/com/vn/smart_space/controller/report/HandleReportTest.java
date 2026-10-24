package com.vn.smart_space.controller.report;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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

public class HandleReportTest {

    private static final String BASE_URL = "http://localhost:8989";
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";

    @BeforeAll
    static void setupConsoleEncodingAndCheckBackendRunning() {
        try {
            System.setOut(new PrintStream(System.out, true, StandardCharsets.UTF_8.name()));
            System.setErr(new PrintStream(System.err, true, StandardCharsets.UTF_8.name()));
        } catch (Exception ignored) {
        }

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
            System.err.println("================================================================================");
            fail("[LỖI] Backend chưa được khởi chạy tại " + BASE_URL + "! Vui lòng bật backend trước khi chạy test.");
        }
    }

    private String generateToken(String email, String userId, String scope) throws Exception {
        Date issueTime = new Date();
        Date expiryTime = new Date(System.currentTimeMillis() + 3600_000);
        JWSHeader header = new JWSHeader(JWSAlgorithm.HS512);
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .subject(email)
                .issuer("smartspace.vn")
                .issueTime(issueTime)
                .expirationTime(expiryTime)
                .jwtID(UUID.randomUUID().toString())
                .claim("scope", scope)
                .claim("userId", userId)
                .claim("deviceId", "test-device-uuid")
                .claim("tokenType", "access")
                .build();

        SignedJWT signedJWT = new SignedJWT(header, claims);
        signedJWT.sign(new MACSigner(SIGNER_KEY.getBytes(StandardCharsets.UTF_8)));
        return signedJWT.serialize();
    }

    @Test
    @DisplayName("Mô phỏng quy trình E2E: Client tạo report -> Admin phân công -> Staff xử lý hoàn thành")
    void testEndToEnd_CreateAssignAndHandleReport() throws Exception {
        System.out.println("================================================================================");
        System.out.println(">> [TEST E2E] Bắt đầu quy trình kiểm thử hoàn chỉnh: Tạo -> Phân công -> Xử lý");
        System.out.println(">> Target Server : " + BASE_URL);
        System.out.println("================================================================================");

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        ObjectMapper mapper = new ObjectMapper();

        // -------------------------------------------------------------------------
        // BƯỚC 1: Client 'u2' tạo phản ánh sự cố mới
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 1] Client 'u2' gửi yêu cầu tạo phản ánh sự cố...");
        String clientToken = generateToken("user@gmail.com", "u2", "client");

        String createPayload = """
        {
          "title": "Sự cố vỡ ống nước sinh hoạt tòa B",
          "description": "Đường ống cấp nước tại hành lang tầng 3 tòa B bị rò rỉ lớn, nước tràn ra sàn.",
          "image_urls": ["https://tse3.mm.bing.net/th/id/OIP._BzTy6Ceb3JFCM3fEAsqZAHaFj?r=0&rs=1&pid=ImgDetMain&o=7&rm=3"],
          "latitude": 10.8506,
          "longitude": 106.7720,
          "is_anonymous": false,
          "address": "Tòa B, chung cư SmartSpace",
          "location_description": "Hành lang tầng 3"
        }
        """;

        HttpRequest createRequest = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + clientToken)
                .POST(HttpRequest.BodyPublishers.ofString(createPayload, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> createResponse = client.send(createRequest, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, createResponse.statusCode(), "Tạo report phải trả về 200 OK");

        JsonNode createNode = mapper.readTree(createResponse.body());
        String reportId = createNode.path("data").path("id").asText();
        assertNotNull(reportId, "Phải lấy được ID của report");
        assertFalse(reportId.isEmpty(), "Report ID không được rỗng");
        System.out.println(">> [BƯỚC 1 OK] Đã tạo report thành công! Report ID: " + reportId);

        // -------------------------------------------------------------------------
        // BƯỚC 2: Admin 'u1' phân công xử lý cho Staff 'u5'
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 2] Admin 'u1' phân công report " + reportId + " cho Staff 'u5'...");
        String adminToken = generateToken("admin@gmail.com", "u1", "ROLE_admin");

        String assignPayload = """
        {
          "staffId": "u5",
          "severity": "high"
        }
        """;

        HttpRequest assignRequest = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/admin/reports/" + reportId + "/assign"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + adminToken)
                .POST(HttpRequest.BodyPublishers.ofString(assignPayload, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> assignResponse = client.send(assignRequest, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, assignResponse.statusCode(), "Phân công report phải trả về 200 OK");
        System.out.println(">> [BƯỚC 2 OK] Phân công thành công! Status chuyển sang: processing");

        // -------------------------------------------------------------------------
        // BƯỚC 3: Staff 'u5' xử lý và gửi xác nhận hoàn tất kèm ghi chú & ảnh minh chứng
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 3] Staff 'u5' hoàn tất xử lý phản ánh (Slide to confirm submit)...");
        String staffToken = generateToken("staff@gmail.com", "u5", "ROLE_staff");

        String completePayload = """
        {
          "note": "Đã thay thế đoạn ống nước bị vỡ và dọn dẹp sạch sàn tầng 3. Áp suất nước ổn định.",
          "image_urls": [
            "https://tse3.mm.bing.net/th/id/OIP._BzTy6Ceb3JFCM3fEAsqZAHaFj?r=0&rs=1&pid=ImgDetMain&o=7&rm=3",
            "https://tse3.mm.bing.net/th/id/OIP._BzTy6Ceb3JFCM3fEAsqZAHaFj?r=0&rs=1&pid=ImgDetMain&o=7&rm=3"
          ]
        }
        """;

        HttpRequest completeRequest = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports/" + reportId + "/complete"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + staffToken)
                .POST(HttpRequest.BodyPublishers.ofString(completePayload, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> completeResponse = client.send(completeRequest, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

        System.out.println("================================================================================");
        System.out.println(">> [KẾT QUẢ XỬ LÝ REPORT]");
        System.out.println(">> HTTP Status Code : " + completeResponse.statusCode());
        System.out.println(">> Response Body    : " + completeResponse.body());
        System.out.println("================================================================================");

        assertEquals(200, completeResponse.statusCode(), "Xử lý report phải trả về 200 OK");

        JsonNode completeNode = mapper.readTree(completeResponse.body());
        assertTrue(completeNode.path("success").asBoolean(), "Phản hồi phải có success: true");

        JsonNode reportData = completeNode.path("data");
        assertEquals("processed", reportData.path("status").asText(), "Trạng thái report phải là 'processed'");
        assertEquals("Đã thay thế đoạn ống nước bị vỡ và dọn dẹp sạch sàn tầng 3. Áp suất nước ổn định.",
                reportData.path("resolved_note").asText(), "Ghi chú xử lý phải khớp với dữ liệu gửi lên");

        JsonNode resolvedImages = reportData.path("resolved_image_urls");
        assertTrue(resolvedImages.isArray(), "Danh sách ảnh xử lý phải là array");
        assertEquals(2, resolvedImages.size(), "Phải lưu đủ 2 ảnh minh chứng");

        System.out.println(">> [THÀNH CÔNG] Toàn bộ quy trình E2E Tạo -> Phân công -> Xử lý hoàn tất chính xác 100%!");
    }
}
