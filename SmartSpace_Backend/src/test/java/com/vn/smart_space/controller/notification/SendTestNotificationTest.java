package com.vn.smart_space.controller.notification;

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

public class SendTestNotificationTest {

    private static final String BASE_URL = "http://localhost:8989";
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";
    private static final ObjectMapper MAPPER = new ObjectMapper();

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

    private String generateAdminToken() throws Exception {
        Date issueTime = new Date();
        Date expiryTime = new Date(System.currentTimeMillis() + 3600_000);
        JWSHeader header = new JWSHeader(JWSAlgorithm.HS512);
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .subject("admin@gmail.com")
                .issuer("smartspace.vn")
                .issueTime(issueTime)
                .expirationTime(expiryTime)
                .jwtID(UUID.randomUUID().toString())
                .claim("scope", "ROLE_admin")
                .claim("userId", "u1")
                .claim("deviceId", "test-admin-device")
                .claim("tokenType", "access")
                .build();

        SignedJWT signedJWT = new SignedJWT(header, claims);
        signedJWT.sign(new MACSigner(SIGNER_KEY.getBytes(StandardCharsets.UTF_8)));
        return signedJWT.serialize();
    }

    @Test
    @DisplayName("Gửi thông báo thử nghiệm đa ngôn ngữ (VI/EN theo CSDL) tới toàn bộ người dùng")
    void testBroadcastTestNotification() throws Exception {
        System.out.println("================================================================================");
        System.out.println(">> [TEST BROADCAST NOTIFICATION] Gửi thông báo test đa ngôn ngữ cho toàn bộ user");
        System.out.println(">> Target Server : " + BASE_URL);
        System.out.println("================================================================================");

        String adminToken = generateAdminToken();

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/notifications/broadcast-test"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + adminToken)
                .POST(HttpRequest.BodyPublishers.noBody())
                .build();

        System.out.println(">> Gửi POST /notifications/broadcast-test...");
        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

        System.out.println(">> HTTP Status: " + response.statusCode());
        System.out.println(">> Phản hồi: " + response.body());

        assertEquals(200, response.statusCode(), "Phản hồi API phải là HTTP 200 OK");

        JsonNode root = MAPPER.readTree(response.body());
        assertTrue(root.path("success").asBoolean(), "Trường 'success' phải là true");
        String respMsg = root.path("message").asText();
        assertTrue(respMsg.contains("notification.test.success") || respMsg.contains("thông báo test") || respMsg.toLowerCase().contains("test notification"),
                "Thông điệp phản hồi phải là thông báo thành công: " + respMsg);

        JsonNode data = root.path("data");
        assertNotNull(data, "Dữ liệu trả về không được null");
        int totalSent = data.path("totalSent").asInt();
        int viCount = data.path("viCount").asInt();
        int enCount = data.path("enCount").asInt();

        System.out.println(String.format(">> [KẾT QUẢ THÀNH CÔNG] Tổng số người dùng nhận được: %d (Tiếng Việt: %d, Tiếng Anh: %d)",
                totalSent, viCount, enCount));

        assertTrue(totalSent > 0, "Phải gửi thành công ít nhất 1 thông báo tới người dùng");
        assertEquals(totalSent, viCount + enCount, "Tổng số thông báo phải bằng tổng tiếng Việt + tiếng Anh");

        JsonNode details = data.path("details");
        if (details.isArray() && details.size() > 0) {
            System.out.println(">> Danh sách chi tiết người dùng đã nhận thông báo:");
            for (JsonNode item : details) {
                System.out.println(String.format("   - User [%s] (%s | %s) -> Lang: %s | Tiêu đề: '%s'",
                        item.path("userId").asText(),
                        item.path("role").asText(),
                        item.path("email").asText(),
                        item.path("language").asText(),
                        item.path("title").asText()));
            }
        }
        System.out.println("================================================================================");
    }
}
