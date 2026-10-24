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
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Admin quản lý người dùng (/admin/users). Dựa trên seed_data.sql:
 * u1 = admin, u5 = staff, u2 = client có phản ánh ẩn danh r3, r15.
 */
public class AdminUserManagementTest {

    // Ghi đè bằng -Dsmartspace.baseUrl=http://localhost:<port> khi backend chạy cổng khác
    private static final String BASE_URL = System.getProperty("smartspace.baseUrl", "http://localhost:8989");
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";

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

    @Test
    @DisplayName("Danh sach chi gom client, co reportCount, khong lo admin/staff")
    void testListUsers_OnlyClients() throws Exception {
        HttpResponse<String> res = get("/admin/users?page=1&size=50&sort=newest", adminToken());

        assertEquals(200, res.statusCode());
        String body = res.body();
        assertTrue(body.contains("\"content\""), "Phai tra ve PageResponse");
        assertTrue(body.contains("\"reportCount\""), "Moi dong phai co reportCount");
        assertTrue(body.contains("user@gmail.com"), "Phai co client u2");
        assertFalse(body.contains("admin@gmail.com"), "Khong duoc tra ve admin");
        assertFalse(body.contains("staff1@gmail.com"), "Khong duoc tra ve staff");
    }

    @Test
    @DisplayName("Tim kiem theo email tra ve dung nguoi dung")
    void testListUsers_Search() throws Exception {
        HttpResponse<String> res = get("/admin/users?search=cudan@gmail", adminToken());

        assertEquals(200, res.statusCode());
        assertTrue(res.body().contains("cudan@gmail.com"));
        assertFalse(res.body().contains("user@gmail.com"));
    }

    @Test
    @DisplayName("Size vuot gioi han bi gioi han ve 50")
    void testListUsers_PageSizeClamped() throws Exception {
        HttpResponse<String> res = get("/admin/users?page=1&size=100000", adminToken());

        assertEquals(200, res.statusCode());
        assertTrue(res.body().contains("\"pageSize\":50"), "pageSize phai bi gioi han ve 50");
    }

    @Test
    @DisplayName("Client khong duoc truy cap API quan ly nguoi dung")
    void testListUsers_ForbiddenForClient() throws Exception {
        HttpResponse<String> res = get("/admin/users", token("user@gmail.com", "u2", "ROLE_client"));

        assertEquals(403, res.statusCode());
    }

    @Test
    @DisplayName("Thong ke tra ve du KPI va top nguoi dong gop")
    void testStatistics() throws Exception {
        HttpResponse<String> res = get("/admin/users/statistics", adminToken());

        assertEquals(200, res.statusCode());
        String body = res.body();
        for (String field : new String[] { "totalUsers", "newUsers", "newUsersPrevious",
                "activeReporters", "reports", "reportsPrevious", "topReporters" }) {
            assertTrue(body.contains("\"" + field + "\""), "Thieu truong " + field);
        }
    }

    @Test
    @DisplayName("Trend zero-fill du so bucket: daily 30, weekly 12, monthly 12")
    void testTrend_BucketCount() throws Exception {
        assertEquals(30, countMatches(get("/admin/users/trend?period=daily", adminToken()).body(), "\"date\""));
        assertEquals(12, countMatches(get("/admin/users/trend?period=weekly", adminToken()).body(), "\"date\""));
        assertEquals(12, countMatches(get("/admin/users/trend?period=monthly", adminToken()).body(), "\"date\""));
        // Period la → fallback daily
        assertEquals(30, countMatches(get("/admin/users/trend?period=abc", adminToken()).body(), "\"date\""));
    }

    @Test
    @DisplayName("Chi tiet nguoi dung khong lo phan anh an danh")
    void testDetail_HidesAnonymousReports() throws Exception {
        HttpResponse<String> res = get("/admin/users/u2", adminToken());

        assertEquals(200, res.statusCode());
        String body = res.body();
        assertTrue(body.contains("\"reportStats\""));
        assertTrue(body.contains("\"recentReports\""));
        assertFalse(body.contains("\"id\":\"r3\""), "Phan anh an danh r3 khong duoc xuat hien");
        assertFalse(body.contains("\"id\":\"r15\""), "Phan anh an danh r15 khong duoc xuat hien");
    }

    @Test
    @DisplayName("Chi tiet khong tra cuu duoc staff/admin qua API nguoi dung")
    void testDetail_NotFoundForStaff() throws Exception {
        assertEquals(404, get("/admin/users/u5", adminToken()).statusCode());
        assertEquals(404, get("/admin/users/u1", adminToken()).statusCode());
    }

    private static HttpResponse<String> get(String path, String token) throws Exception {
        HttpResponse<String> res = HTTP.send(
                HttpRequest.newBuilder(URI.create(BASE_URL + path))
                        .header("Authorization", "Bearer " + token)
                        .GET().build(),
                HttpResponse.BodyHandlers.ofString());
        System.out.println(">> GET " + path + " → " + res.statusCode());
        return res;
    }

    private static int countMatches(String text, String needle) {
        Matcher m = Pattern.compile(Pattern.quote(needle)).matcher(text);
        int count = 0;
        while (m.find()) {
            count++;
        }
        return count;
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
