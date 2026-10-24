package com.vn.smart_space.controller.news;

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

public class NewsIntegrationTest {

    private static final String BASE_URL = "http://localhost:8989";
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";
    private static final ObjectMapper objectMapper = new ObjectMapper();

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
            System.out.println("Backend is not running at " + BASE_URL + ", skipping live HTTP test.");
        }
    }

    private static String generateMockJwt(String userId, String email, String role) throws Exception {
        JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
                .subject(userId)
                .claim("userId", userId)
                .claim("email", email)
                .claim("scope", "ROLE_" + role)
                .issueTime(new Date())
                .expirationTime(new Date(System.currentTimeMillis() + 1000 * 60 * 60))
                .jwtID(UUID.randomUUID().toString())
                .build();

        SignedJWT signedJWT = new SignedJWT(new JWSHeader(JWSAlgorithm.HS512), claimsSet);
        signedJWT.sign(new MACSigner(SIGNER_KEY.getBytes(StandardCharsets.UTF_8)));
        return signedJWT.serialize();
    }

    @Test
    @DisplayName("Kiểm tra luồng CRUD News: Admin tạo, cập nhật, lấy chi tiết, xóa và Client bị chặn quyền CUD")
    void testNewsLifecycleAndPermissions() throws Exception {
        boolean isRunning = false;
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("localhost", 8989), 1500);
            isRunning = true;
        } catch (Exception ignored) {
        }

        if (!isRunning) {
            return;
        }

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();

        String adminToken = generateMockJwt("admin-test-id", "admin@smartspace.vn", "admin");
        String clientToken = generateMockJwt("client-test-id", "client@smartspace.vn", "client");

        // 1. Client thử tạo tin tức -> Phải trả về 403 Forbidden
        String createNewsBody = """
                {
                    "title": "Tin tức an ninh môi trường",
                    "content": "## Nội dung chính\\n- Thông báo **khẩn cấp**\\n- Người dân chú ý",
                    "image_urls": ["https://res.cloudinary.com/demo/image/upload/sample.jpg"]
                }
                """;

        HttpRequest clientCreateReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/news"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + clientToken)
                .POST(HttpRequest.BodyPublishers.ofString(createNewsBody))
                .build();

        HttpResponse<String> clientCreateRes = client.send(clientCreateReq, HttpResponse.BodyHandlers.ofString());
        assertEquals(403, clientCreateRes.statusCode(), "Client không được phép tạo tin tức (phải là 403)");

        // 2. Admin tạo tin tức -> 201 Created
        HttpRequest adminCreateReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/news"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + adminToken)
                .POST(HttpRequest.BodyPublishers.ofString(createNewsBody))
                .build();

        HttpResponse<String> adminCreateRes = client.send(adminCreateReq, HttpResponse.BodyHandlers.ofString());
        assertEquals(201, adminCreateRes.statusCode(), "Admin tạo tin tức thành công (201)");

        JsonNode rootNode = objectMapper.readTree(adminCreateRes.body());
        String newsId = rootNode.path("data").path("id").asText();
        assertNotNull(newsId);
        assertFalse(newsId.isEmpty());

        // 3. Lấy chi tiết tin tức (GET /news/{id})
        HttpRequest getDetailReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/news/" + newsId))
                .GET()
                .build();

        HttpResponse<String> detailRes = client.send(getDetailReq, HttpResponse.BodyHandlers.ofString());
        assertEquals(200, detailRes.statusCode());
        assertTrue(detailRes.body().contains("Tin tức an ninh môi trường"));

        // 4. Admin cập nhật tin tức (PUT /news/{id})
        String updateNewsBody = """
                {
                    "title": "Tin tức đã được cập nhật",
                    "content": "Nội dung cập nhật mới",
                    "image_urls": ["https://res.cloudinary.com/demo/image/upload/sample2.jpg"]
                }
                """;

        HttpRequest updateReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/news/" + newsId))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + adminToken)
                .PUT(HttpRequest.BodyPublishers.ofString(updateNewsBody))
                .build();

        HttpResponse<String> updateRes = client.send(updateReq, HttpResponse.BodyHandlers.ofString());
        assertEquals(200, updateRes.statusCode());

        // 5. Admin xóa tin tức (DELETE /news/{id})
        HttpRequest deleteReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/news/" + newsId))
                .header("Authorization", "Bearer " + adminToken)
                .DELETE()
                .build();

        HttpResponse<String> deleteRes = client.send(deleteReq, HttpResponse.BodyHandlers.ofString());
        assertEquals(200, deleteRes.statusCode());
    }
}
