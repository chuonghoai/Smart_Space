package com.vn.smart_space.controller.staff;

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
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * Dashboard Quản lý nhân viên (/admin/staffs/statistics, /admin/staffs/trend). Dựa trên seed_data.sql:
 * u1 = admin, u2 = client.
 */
public class StaffDashboardTest {

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
    @DisplayName("Thong ke tra ve du KPI va workload")
    void testStatistics() throws Exception {
        HttpResponse<String> res = send("GET", "/admin/staffs/statistics", adminToken(), null);

        assertEquals(200, res.statusCode());
        String body = res.body();
        for (String field : new String[] { "totalStaff", "activeStaff", "blockedStaff", "processingReports",
                "resolved", "resolvedPrevious", "avgResolutionMinutes", "avgResolutionMinutesPrevious",
                "workload" }) {
            assertTrue(body.contains("\"" + field + "\""), "Thieu truong " + field);
        }
        assertFalse(body.contains("\"password\""), "Khong duoc tra ve password");
    }

    @Test
    @DisplayName("Trend zero-fill du so bucket va co 2 series assigned/resolved")
    void testTrend_BucketCount() throws Exception {
        String daily = send("GET", "/admin/staffs/trend?period=daily", adminToken(), null).body();
        assertEquals(30, countMatches(daily, "\"date\""));
        assertEquals(30, countMatches(daily, "\"assigned\""));
        assertEquals(30, countMatches(daily, "\"resolved\""));

        assertEquals(12, countMatches(
                send("GET", "/admin/staffs/trend?period=weekly", adminToken(), null).body(), "\"date\""));
        assertEquals(12, countMatches(
                send("GET", "/admin/staffs/trend?period=monthly", adminToken(), null).body(), "\"date\""));
        // Period la → fallback daily
        assertEquals(30, countMatches(
                send("GET", "/admin/staffs/trend?period=abc", adminToken(), null).body(), "\"date\""));
    }

    @Test
    @DisplayName("Client khong duoc truy cap thong ke nhan vien")
    void testForbiddenForClient() throws Exception {
        String clientToken = token("user@gmail.com", "u2", "ROLE_client");
        assertEquals(403, send("GET", "/admin/staffs/statistics", clientToken, null).statusCode());
        assertEquals(403, send("GET", "/admin/staffs/trend", clientToken, null).statusCode());
    }

    /**
     * Thống kê "đã xử lý" dùng updatedAt của báo cáo processed. Giả định này chỉ đúng khi
     * processed là trạng thái cuối. Nếu test này fail → cần chuyển sang cột resolvedAt riêng.
     */
    @Test
    @DisplayName("Bao cao processed khong duoc chuyen trang thai (khoa gia dinh dung updatedAt)")
    void testProcessedIsTerminal() throws Exception {
        // Lấy 1 báo cáo đang processed thật trong DB (không giả định theo seed)
        String list = send("GET", "/admin/reports?status=processed&size=1", adminToken(), null).body();
        Matcher idMatcher = Pattern.compile("\"content\":\\[\\{\"id\":\"([^\"]+)\"").matcher(list);
        assumeTrue(idMatcher.find(), "Khong co bao cao processed nao de kiem tra");
        String reportId = idMatcher.group(1);

        for (String next : new String[] { "processing", "pending", "rejected" }) {
            HttpResponse<String> res = send("PATCH", "/admin/reports/" + reportId + "/status", adminToken(),
                    "{\"status\":\"" + next + "\"}");
            assertNotEquals(200, res.statusCode(),
                    "processed -> " + next + " khong duoc phep (thong ke dua tren updatedAt se sai)");
        }
    }

    private static HttpResponse<String> send(String method, String path, String token, String json)
            throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(BASE_URL + path))
                .header("Authorization", "Bearer " + token);
        if (json == null) {
            builder.method(method, HttpRequest.BodyPublishers.noBody());
        } else {
            builder.header("Content-Type", "application/json")
                    .method(method, HttpRequest.BodyPublishers.ofString(json));
        }
        HttpResponse<String> res = HTTP.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        System.out.println(">> " + method + " " + path + " → " + res.statusCode());
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
