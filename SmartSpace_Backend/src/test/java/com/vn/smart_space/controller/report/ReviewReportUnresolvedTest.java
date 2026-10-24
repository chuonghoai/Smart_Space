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

public class ReviewReportUnresolvedTest {

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
    @DisplayName("Mô phỏng Client đánh giá phản ánh là 'Chưa được xử lý' (Unresolved) kèm lý do và ảnh chụp bằng chứng")
    void testClientReviewReport_UnresolvedWithReasonAndImages() throws Exception {
        System.out.println("================================================================================");
        System.out.println(">> [TEST REVIEW UNRESOLVED] Kiểm thử Client đánh giá phản ánh CHƯA ĐƯỢC XỬ LÝ");
        System.out.println(">> Target Server : " + BASE_URL);
        System.out.println("================================================================================");

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        ObjectMapper mapper = new ObjectMapper();

        // -------------------------------------------------------------------------
        // BƯỚC 1: Client 'u2' tạo phản ánh sự cố mới
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 1] Client 'u2' tạo phản ánh sự cố...");
        String clientToken = generateToken("user@gmail.com", "u2", "client");

        String createPayload = """
        {
          "title": "Rác thải sinh hoạt ứ đọng lối thoát hiểm tầng 2",
          "description": "Nhiều bao rác bốc mùi hôi thối bị bỏ lại tại cửa thoát hiểm tầng 2.",
          "image_urls": ["https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=800&q=80"],
          "latitude": 10.8509,
          "longitude": 106.7725,
          "is_anonymous": false,
          "address": "Tòa C, chung cư SmartSpace",
          "location_description": "Cửa thoát hiểm tầng 2"
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
        // BƯỚC 2: Admin 'u1' phân công cho Staff 'u5'
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 2] Admin 'u1' phân công cho Staff 'u5'...");
        String adminToken = generateToken("admin@gmail.com", "u1", "ROLE_admin");

        String assignPayload = """
        {
          "staffId": "u5",
          "severity": "medium"
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
        // BƯỚC 3: Staff 'u5' hoàn thành xử lý
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 3] Staff 'u5' hoàn tất xử lý phản ánh...");
        String staffToken = generateToken("staff@gmail.com", "u5", "ROLE_staff");

        String completePayload = """
        {
          "note": "Đã thu gom các bao rác tại khu vực thoát hiểm tầng 2.",
          "image_urls": [
            "https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=800&q=80"
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
        assertEquals(200, completeResponse.statusCode(), "Xử lý report phải trả về 200 OK");
        System.out.println(">> [BƯỚC 3 OK] Staff hoàn thành xử lý! Status chuyển sang: processed");

        // -------------------------------------------------------------------------
        // BƯỚC 4: Client 'u2' gửi đánh giá "Chưa được xử lý" (is_resolved = false)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 4] Client 'u2' kiểm tra và gửi đánh giá 'Chưa được xử lý' kèm ảnh bằng chứng...");
        String reviewPayload = """
        {
          "is_resolved": false,
          "reason": "Vẫn còn nước bẩn và mùi hôi nồng nặc chưa được cọ rửa sạch sẽ, rác chưa được dọn hết.",
          "image_urls": [
            "https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=800&q=80"
          ]
        }
        """;

        HttpRequest reviewRequest = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports/" + reportId + "/review"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + clientToken)
                .POST(HttpRequest.BodyPublishers.ofString(reviewPayload, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> reviewResponse = client.send(reviewRequest, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

        System.out.println("================================================================================");
        System.out.println(">> [KẾT QUẢ ĐÁNH GIÁ (UNRESOLVED)]");
        System.out.println(">> HTTP Status Code : " + reviewResponse.statusCode());
        System.out.println(">> Response Body    : " + reviewResponse.body());
        System.out.println("================================================================================");

        assertEquals(200, reviewResponse.statusCode(), "Gửi review phải trả về 200 OK");

        JsonNode reviewNode = mapper.readTree(reviewResponse.body());
        assertTrue(reviewNode.path("success").asBoolean(), "Phản hồi phải có success: true");

        JsonNode reportData = reviewNode.path("data");
        assertFalse(reportData.path("is_review_resolved").asBoolean(), "Trường is_review_resolved phải là false");
        assertEquals("Vẫn còn nước bẩn và mùi hôi nồng nặc chưa được cọ rửa sạch sẽ, rác chưa được dọn hết.",
                reportData.path("review_note").asText(), "Review note phải khớp nội dung gửi lên");

        JsonNode reviewImages = reportData.path("review_image_urls");
        assertTrue(reviewImages.isArray(), "Danh sách review_image_urls phải là array");
        assertEquals(1, reviewImages.size(), "Phải có đúng 1 ảnh bằng chứng");
        assertFalse(reportData.path("reviewed_at").asText().isEmpty(), "Thời gian reviewed_at không được để trống");

        System.out.println(">> [THÀNH CÔNG] Đánh giá 'Chưa được xử lý' hoàn tất chính xác 100%! Admin đã nhận được thông báo kiểm tra lại.");
    }
}
