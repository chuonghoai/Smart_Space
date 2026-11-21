package com.vn.smart_space.controller.admin;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Date;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Biểu quyết khóa tài khoản (/admin/lock-requests, /admin/users/{id}/unlock).
 * Dựa trên seed_data.sql: u1 = admin, u5 = staff, u2 = client đang hoạt động.
 * Chỉ gồm các case không để lại side-effect (không tạo đề xuất thật, không khóa/mở khóa thật).
 */
public class AccountLockRequestManagementTest {

    private static final String BASE_URL = System.getProperty("smartspace.baseUrl", "http://localhost:8989");
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";
    private static final String VALID_REASON = "Đăng nhiều phản ánh sai sự thật và spam liên tục.";

    private static final HttpClient HTTP = HttpClient.newHttpClient();

    @BeforeAll
    static void checkBackendRunning() {
        URI base = URI.create(BASE_URL);
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(base.getHost(), base.getPort()), 1500);
        } catch (Exception e) {
            fail("[LOI] Backend chua chay tai " + BASE_URL + "! Bat backend truoc khi chay test.");
        }
    }

    // Test Case ID: SMP-170
    // Description: Kiểm tra Admin lấy danh sách đề xuất khóa tài khoản pending và số lượng chờ biểu quyết
    @Test
    @DisplayName("Danh sach va dem de xuat cho admin")
    void testListAndPendingCount() throws Exception {
        HttpResponse<String> list = get("/admin/lock-requests?status=pending", adminToken());
        assertEquals(200, list.statusCode());
        assertTrue(list.body().contains("\"content\""));

        HttpResponse<String> count = get("/admin/lock-requests/pending-count", adminToken());
        assertEquals(200, count.statusCode());
        assertTrue(count.body().contains("\"awaitingMyVote\""));
    }

    // Test Case ID: SMP-171
    // Description: Kiểm tra Staff và Client bị chặn 403 khi gọi các API quản lý đề xuất khóa và mở khóa tài khoản
    @Test
    @DisplayName("Staff va client khong duoc truy cap")
    void testForbiddenForNonAdmin() throws Exception {
        assertEquals(403, get("/admin/lock-requests", token("staff1@gmail.com", "u5", "ROLE_staff")).statusCode());
        assertEquals(403, post("/admin/lock-requests",
                body("u2", VALID_REASON, "[\"https://x/a.jpg\"]"),
                token("user@gmail.com", "u2", "ROLE_client")).statusCode());
        assertEquals(403, put("/admin/users/u2/unlock", "{\"reason\":\"Đã xác minh lại\"}",
                token("user@gmail.com", "u2", "ROLE_client")).statusCode());
    }

    // Test Case ID: SMP-172
    // Description: Kiểm tra API tạo đề xuất khóa trả về 400 khi lý do ngắn/thiếu ảnh bằng chứng và 404 khi đối tượng là staff
    @Test
    @DisplayName("Tao de xuat: ly do qua ngan / thieu bang chung / doi tuong la staff bi tu choi")
    void testCreate_ValidationErrors() throws Exception {
        assertEquals(400, post("/admin/lock-requests", body("u2", "ngắn", "[\"https://x/a.jpg\"]"),
                adminToken()).statusCode());
        assertEquals(400, post("/admin/lock-requests", body("u2", VALID_REASON, "[]"),
                adminToken()).statusCode());
        assertEquals(404, post("/admin/lock-requests", body("u5", VALID_REASON, "[\"https://x/a.jpg\"]"),
                adminToken()).statusCode());
    }

    // Test Case ID: SMP-173
    // Description: Kiểm tra API bỏ phiếu đề xuất khóa trả về 400 với quyết định không hợp lệ và 404 khi đề xuất không tồn tại
    @Test
    @DisplayName("Bo phieu: phieu khong hop le / de xuat khong ton tai")
    void testVote_Errors() throws Exception {
        assertEquals(400, post("/admin/lock-requests/not-exist/votes", "{\"decision\":\"maybe\"}",
                adminToken()).statusCode());
        assertEquals(404, post("/admin/lock-requests/not-exist/votes", "{\"decision\":\"approve\"}",
                adminToken()).statusCode());
    }

    // Test Case ID: SMP-174
    // Description: Kiểm tra API mở khóa người dùng trả về 400 khi người dùng đang hoạt động hoặc thiếu lý do
    @Test
    @DisplayName("Mo khoa nguoi dung dang hoat dong bi tu choi; thieu ly do bi tu choi")
    void testUnlock_Errors() throws Exception {
        assertEquals(400, put("/admin/users/u2/unlock", "{\"reason\":\"Đã xác minh lại thông tin\"}",
                adminToken()).statusCode());
        assertEquals(400, put("/admin/users/u2/unlock", "{\"reason\":\"\"}", adminToken()).statusCode());
    }

    private static String body(String targetId, String reason, String imagesJson) {
        return "{\"targetUserId\":\"" + targetId + "\",\"reason\":\"" + reason + "\",\"evidenceImageUrls\":"
                + imagesJson + "}";
    }

    private static HttpResponse<String> get(String path, String token) throws Exception {
        return send(HttpRequest.newBuilder(URI.create(BASE_URL + path))
                .header("Authorization", "Bearer " + token).GET().build(), "GET " + path);
    }

    private static HttpResponse<String> post(String path, String json, String token) throws Exception {
        return send(HttpRequest.newBuilder(URI.create(BASE_URL + path))
                .header("Authorization", "Bearer " + token)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json)).build(), "POST " + path);
    }

    private static HttpResponse<String> put(String path, String json, String token) throws Exception {
        return send(HttpRequest.newBuilder(URI.create(BASE_URL + path))
                .header("Authorization", "Bearer " + token)
                .header("Content-Type", "application/json")
                .PUT(HttpRequest.BodyPublishers.ofString(json)).build(), "PUT " + path);
    }

    private static HttpResponse<String> send(HttpRequest request, String label) throws Exception {
        HttpResponse<String> res = HTTP.send(request, HttpResponse.BodyHandlers.ofString());
        System.out.println(">> " + label + " → " + res.statusCode());
        return res;
    }

    private static String adminToken() throws Exception {
        return token("admin@gmail.com", "u1", "ROLE_admin");
    }

    private static String token(String email, String userId, String scope) throws Exception {
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .subject(email)
                .issuer("smartspace.vn")
                .issueTime(new Date())
                .expirationTime(new Date(System.currentTimeMillis() + 3600_000))
                .jwtID(UUID.randomUUID().toString())
                .claim("scope", scope)
                .claim("userId", userId)
                .claim("deviceId", "test-device-uuid")
                .claim("tokenType", "access")
                .build();
        SignedJWT jwt = new SignedJWT(new JWSHeader(JWSAlgorithm.HS512), claims);
        jwt.sign(new MACSigner(SIGNER_KEY.getBytes()));
        return jwt.serialize();
    }
}
