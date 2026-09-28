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

public class AssignReportTest {

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
    @DisplayName("Mô phỏng Client tạo phản ánh và Admin phân công xử lý cho Staff")
    void testCreateAndAssignReport_SimulateRealFlow() throws Exception {
        System.out.println("================================================================================");
        System.out.println(">> [TEST] Bắt đầu mô phỏng luồng tạo phản ánh và phân công...");
        System.out.println(">> Target Server : " + BASE_URL);
        System.out.println("================================================================================");

        // 1. Tạo JWT Bearer Token hợp lệ của User 'u2' (role: client)
        String clientToken = generateToken("user@gmail.com", "u2", "client");

        // 2. Chuẩn bị Payload JSON 100% giống với smartspace_client gửi lên
        String createRequestJson = """
        {
          "title": "Sự cố mất nước sinh hoạt tòa A",
          "description": "Tòa A đang mất nước từ 8h sáng, cần kiểm tra gấp.",
          "image_urls": [],
          "latitude": 10.8506,
          "longitude": 106.7720,
          "is_anonymous": false,
          "address": "Tòa A, chung cư SmartSpace",
          "location_description": "Trạm bơm tầng hầm"
        }
        """;

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();

        HttpRequest createRequest = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + clientToken)
                .POST(HttpRequest.BodyPublishers.ofString(createRequestJson, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> createResponse = client.send(createRequest, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        
        assertEquals(200, createResponse.statusCode(), "HTTP Status phải là 200 OK");
        
        // Extract Report ID from response
        ObjectMapper mapper = new ObjectMapper();
        JsonNode rootNode = mapper.readTree(createResponse.body());
        String reportId = rootNode.path("data").path("id").asText();
        
        assertNotNull(reportId, "Phải lấy được ID của report");
        assertFalse(reportId.isEmpty(), "Report ID không được rỗng");
        
        System.out.println(">> Đã tạo report thành công. Report ID: " + reportId);

        // 3. Tạo JWT Bearer Token hợp lệ của Admin 'u1' (role: admin)
        String adminToken = generateToken("admin@gmail.com", "u1", "admin");
        
        // 4. Admin phân công report cho staff 'u5'
        String assignRequestJson = """
        {
          "staffId": "u5",
          "severity": "high"
        }
        """;
        
        HttpRequest assignRequest = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/admin/reports/" + reportId + "/assign"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + adminToken)
                .POST(HttpRequest.BodyPublishers.ofString(assignRequestJson, StandardCharsets.UTF_8))
                .build();
                
        HttpResponse<String> assignResponse = client.send(assignRequest, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        
        System.out.println("================================================================================");
        System.out.println(">> [KẾT QUẢ] Đã gửi yêu cầu phân công report thành công!");
        System.out.println(">> HTTP Status Code : " + assignResponse.statusCode());
        System.out.println(">> Response Body    : " + assignResponse.body());
        System.out.println(">> Realtime Event   : Vui lòng kiểm tra app Client xem có nhận được thông báo phản ánh đã được tiếp nhận và phân công không.");
        System.out.println("================================================================================");

        assertEquals(200, assignResponse.statusCode(), "HTTP Status phân công phải là 200 OK");
        assertTrue(assignResponse.body().contains("\"success\":true"), "Phản hồi phân công phải thành công");
    }
}
