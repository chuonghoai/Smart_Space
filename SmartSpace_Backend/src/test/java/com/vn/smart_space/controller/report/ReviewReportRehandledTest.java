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

public class ReviewReportRehandledTest {

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
    @DisplayName("Mô phỏng quy trình xử lý lại phản ánh: Unresolved -> Admin Reopen -> Staff xử lý lại -> Client đánh giá mới ghi đè")
    void testRehandledReportReviewFlow() throws Exception {
        System.out.println("================================================================================");
        System.out.println(">> [TEST RE-HANDLED REVIEW] Kiểm thử quy trình Xử lý lại & Đánh giá lại phản ánh");
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
        String clientToken = generateToken("user@gmail.com", "u2", "ROLE_client");

        String createPayload = """
        {
          "title": "Bồn rửa tay sảnh B bị rò rỉ nước",
          "description": "Vòi cấp nước dưới bồn rửa tay sảnh B bị lỏng ốc gây rò rỉ nước ra sàn.",
          "image_urls": ["https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=800&q=80"],
          "latitude": 10.8507,
          "longitude": 106.7721,
          "is_anonymous": false,
          "address": "Tòa B, chung cư SmartSpace",
          "location_description": "Khu vực vệ sinh sảnh B"
        }
        """;

        HttpRequest createReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + clientToken)
                .POST(HttpRequest.BodyPublishers.ofString(createPayload, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> createRes = client.send(createReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, createRes.statusCode(), "Tạo report phải thành công (HTTP 200)");

        JsonNode createNode = mapper.readTree(createRes.body());
        String reportId = createNode.get("data").get("id").asText();
        System.out.println(">> [BƯỚC 1 OK] Đã tạo report thành công! Report ID: " + reportId);

        // -------------------------------------------------------------------------
        // BƯỚC 2: Admin 'u1' phân công cho Staff 'u5'
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 2] Admin 'u1' phân công cho Staff 'u5'...");
        String adminToken = generateToken("admin@gmail.com", "u1", "ROLE_admin");

        String assignPayload = """
        {
          "staffId": "u5",
          "severity": "low"
        }
        """;

        HttpRequest assignReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/admin/reports/" + reportId + "/assign"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + adminToken)
                .POST(HttpRequest.BodyPublishers.ofString(assignPayload, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> assignRes = client.send(assignReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, assignRes.statusCode(), "Phân công report phải thành công (HTTP 200)");
        System.out.println(">> [BƯỚC 2 OK] Phân công thành công! Status chuyển sang: processing");

        // -------------------------------------------------------------------------
        // BƯỚC 3: Staff 'u5' hoàn tất xử lý lần 1 (nhưng chưa đạt yêu cầu)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 3] Staff 'u5' hoàn tất xử lý lần 1...");
        String staffToken = generateToken("staff1@gmail.com", "u5", "ROLE_staff");

        String completePayload1 = """
        {
          "note": "Đã quấn băng tan tạm thời xung quanh vòi cấp.",
          "image_urls": ["https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=800&q=80"]
        }
        """;

        HttpRequest completeReq1 = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports/" + reportId + "/complete"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + staffToken)
                .POST(HttpRequest.BodyPublishers.ofString(completePayload1, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> completeRes1 = client.send(completeReq1, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, completeRes1.statusCode(), "Staff hoàn tất lần 1 phải thành công (HTTP 200)");
        System.out.println(">> [BƯỚC 3 OK] Staff hoàn thành lần 1! Status: processed");

        // -------------------------------------------------------------------------
        // BƯỚC 4: Client 'u2' đánh giá 'Chưa được xử lý' (Unresolved)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 4] Client 'u2' gửi đánh giá Chưa được xử lý...");
        String reviewUnresolvedPayload = """
        {
          "is_resolved": false,
          "reason": "Vẫn còn rỉ nước nhỏ giọt xuống sàn, chưa siết chặt ốc ren.",
          "image_urls": ["https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=800&q=80"]
        }
        """;

        HttpRequest reviewReq1 = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports/" + reportId + "/review"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + clientToken)
                .POST(HttpRequest.BodyPublishers.ofString(reviewUnresolvedPayload, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> reviewRes1 = client.send(reviewReq1, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, reviewRes1.statusCode(), "Đánh giá Unresolved phải thành công (HTTP 200)");
        System.out.println(">> [BƯỚC 4 OK] Client đánh giá Chưa được xử lý thành công!");

        // -------------------------------------------------------------------------
        // BƯỚC 5: Admin 'u1' xem phản hồi và bấm 'Yêu cầu xử lý lại' (re-open về processing)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 5] Admin 'u1' yêu cầu xử lý lại (chuyển status về processing)...");
        String reopenPayload = """
        {
          "status": "processing"
        }
        """;

        HttpRequest reopenReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/admin/reports/" + reportId + "/status"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + adminToken)
                .method("PATCH", HttpRequest.BodyPublishers.ofString(reopenPayload, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> reopenRes = client.send(reopenReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, reopenRes.statusCode(), "Reopen về processing phải thành công (HTTP 200)");
        System.out.println(">> [BƯỚC 5 OK] Reopen thành công! Status chuyển về: processing");

        // -------------------------------------------------------------------------
        // BƯỚC 6: Staff 'u5' xử lý lại lần 2 và hoàn tất (completeReport)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 6] Staff 'u5' xử lý lại lần 2 và hoàn tất...");
        String completePayload2 = """
        {
          "note": "Đã thay gioăng cao su mới và siết chặt ốc ren hoàn toàn khô ráo.",
          "image_urls": ["https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=800&q=80"]
        }
        """;

        HttpRequest completeReq2 = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports/" + reportId + "/complete"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + staffToken)
                .POST(HttpRequest.BodyPublishers.ofString(completePayload2, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> completeRes2 = client.send(completeReq2, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, completeRes2.statusCode(), "Staff hoàn tất lần 2 phải thành công (HTTP 200)");
        System.out.println(">> [BƯỚC 6 OK] Staff xử lý lại xong! Status: processed");

        // -------------------------------------------------------------------------
        // BƯỚC 7: Client GET chi tiết report, kiểm tra review cũ đã được reset
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 7] Client 'u2' GET chi tiết report, kiểm tra review cũ đã bị reset...");
        HttpRequest getDetailReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports/" + reportId))
                .header("Authorization", "Bearer " + clientToken)
                .GET()
                .build();

        HttpResponse<String> getDetailRes = client.send(getDetailReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, getDetailRes.statusCode());

        JsonNode detailData = mapper.readTree(getDetailRes.body()).get("data");
        assertEquals("processed", detailData.get("status").asText());
        assertTrue(detailData.get("is_review_resolved").isNull(), "is_review_resolved phải là null sau khi xử lý lại");
        assertTrue(detailData.get("reviewed_at").isNull(), "reviewed_at phải là null sau khi xử lý lại");
        assertTrue(detailData.get("review_note").isNull(), "review_note cũ phải là null sau khi xử lý lại");
        System.out.println(">> [BƯỚC 7 OK] Dữ liệu review cũ đã được reset về null chính xác!");

        // -------------------------------------------------------------------------
        // BƯỚC 8: Client 'u2' gửi đánh giá mới 'Đã xử lý' 5 sao (ghi đè thành công)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 8] Client 'u2' gửi đánh giá mới 'Đã xử lý' (Resolved 5 sao)...");
        String reviewResolvedPayload = """
        {
          "is_resolved": true,
          "rating": 5,
          "reason": "Lần xử lý này rất tốt, vòi đã hoàn toàn khô ráo. Cảm ơn nhân viên!"
        }
        """;

        HttpRequest reviewReq2 = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports/" + reportId + "/review"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + clientToken)
                .POST(HttpRequest.BodyPublishers.ofString(reviewResolvedPayload, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> reviewRes2 = client.send(reviewReq2, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, reviewRes2.statusCode(), "Đánh giá mới phải thành công (HTTP 200)");

        JsonNode finalData = mapper.readTree(reviewRes2.body()).get("data");
        assertTrue(finalData.get("is_review_resolved").asBoolean(), "is_review_resolved mới phải là true");
        assertEquals(5, finalData.get("rating").asInt(), "rating mới phải là 5");
        assertNotNull(finalData.get("reviewed_at").asText(), "reviewed_at phải có giá trị mới");
        assertEquals("Lần xử lý này rất tốt, vòi đã hoàn toàn khô ráo. Cảm ơn nhân viên!", finalData.get("review_note").asText());

        System.out.println("================================================================================");
        System.out.println(">> [THÀNH CÔNG HOÀN TOÀN] Quy trình Xử lý lại & Đánh giá lại hoạt động chính xác 100%!");
        System.out.println("================================================================================");
    }
}
