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
import java.util.Locale;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Integration test cho GET /admin/reports/map (bản đồ Admin, khung nhìn tuỳ chọn).
 * Yêu cầu backend đang chạy tại BASE_URL.
 */
public class AdminMapReportsTest {

    private static final String BASE_URL = "http://localhost:8989";
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";

    private static final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();
    private static final ObjectMapper mapper = new ObjectMapper();

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

    private HttpResponse<String> get(String path, String token) throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder().uri(URI.create(BASE_URL + path)).GET();
        if (token != null) builder.header("Authorization", "Bearer " + token);
        return client.send(builder.build(), HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
    }

    private String boundsQuery(double minLat, double maxLat, double minLng, double maxLng) {
        return String.format(Locale.US, "minLat=%f&maxLat=%f&minLng=%f&maxLng=%f", minLat, maxLat, minLng, maxLng);
    }

    private String createReport(String token, double lat, double lng) throws Exception {
        String payload = String.format(Locale.US, """
                {
                  "title": "Admin map viewport test report",
                  "description": "Report tạo bởi AdminMapReportsTest",
                  "image_urls": [],
                  "latitude": %f,
                  "longitude": %f,
                  "is_anonymous": false
                }
                """, lat, lng);
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + token)
                .POST(HttpRequest.BodyPublishers.ofString(payload, StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, response.statusCode(), "Tạo report phải trả về 200 OK: " + response.body());
        return mapper.readTree(response.body()).path("data").path("id").asText();
    }

    private void rejectReport(String adminToken, String reportId) throws Exception {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/admin/reports/" + reportId + "/status"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + adminToken)
                .method("PATCH", HttpRequest.BodyPublishers.ofString("{\"status\": \"rejected\"}"))
                .build();
        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        assertEquals(200, response.statusCode(), "Admin từ chối report phải thành công: " + response.body());
    }

    private boolean containsReport(JsonNode reports, String reportId) {
        for (JsonNode report : reports) {
            if (reportId.equals(report.path("id").asText())) return true;
        }
        return false;
    }

    /** Một vùng nhỏ ngẫu nhiên quanh HCM để tránh trùng dữ liệu có sẵn. */
    private double[] randomPoint() {
        ThreadLocalRandom random = ThreadLocalRandom.current();
        return new double[] { 10.70 + random.nextDouble() * 0.2, 106.60 + random.nextDouble() * 0.2 };
    }

    @Test
    @DisplayName("Không có token → 401, client → 403")
    void testAdminMap_Authorization() throws Exception {
        assertEquals(401, get("/admin/reports/map", null).statusCode());

        String clientToken = generateToken("user@gmail.com", "u2", "ROLE_client");
        assertEquals(403, get("/admin/reports/map", clientToken).statusCode(),
                "Client không được gọi API bản đồ của admin");
    }

    @Test
    @DisplayName("Không truyền bounds → toàn bản đồ, response có reports + truncated")
    void testAdminMap_NoBoundsKeepsWholeMap() throws Exception {
        String adminToken = generateToken("admin@gmail.com", "u1", "ROLE_admin");

        HttpResponse<String> response = get("/admin/reports/map?limit=5", adminToken);
        assertEquals(200, response.statusCode(), response.body());
        JsonNode data = mapper.readTree(response.body()).path("data");
        assertTrue(data.path("reports").isArray(), "Response phải có mảng reports");
        assertTrue(data.has("truncated"), "Response phải có trường truncated");
        assertTrue(data.path("reports").size() <= 5, "Không vượt quá limit");
    }

    @Test
    @DisplayName("Bounds thiếu hoặc sai → 400")
    void testAdminMap_InvalidBounds() throws Exception {
        String adminToken = generateToken("admin@gmail.com", "u1", "ROLE_admin");

        assertEquals(400, get("/admin/reports/map?minLat=10.7&maxLat=10.9", adminToken).statusCode(),
                "Chỉ truyền một phần bounds phải trả về 400");
        assertEquals(400, get("/admin/reports/map?" + boundsQuery(10.9, 10.7, 106.6, 106.8), adminToken).statusCode(),
                "minLat > maxLat phải trả về 400");
        assertEquals(400, get("/admin/reports/map?" + boundsQuery(10.7, 10.9, 106.6, 190), adminToken).statusCode(),
                "Longitude ngoài [-180, 180] phải trả về 400");
    }

    @Test
    @DisplayName("Lọc đúng khung nhìn và admin vẫn thấy report rejected")
    void testAdminMap_BoundsAndRejectedVisible() throws Exception {
        String clientToken = generateToken("user@gmail.com", "u2", "client");
        String adminToken = generateToken("admin@gmail.com", "u1", "ROLE_admin");

        double[] point = randomPoint();
        String reportId = createReport(clientToken, point[0], point[1]);
        String inside = boundsQuery(point[0] - 0.0005, point[0] + 0.0005, point[1] - 0.0005, point[1] + 0.0005);
        String outside = boundsQuery(point[0] + 0.01, point[0] + 0.02, point[1] + 0.01, point[1] + 0.02);

        JsonNode insideData = mapper.readTree(get("/admin/reports/map?" + inside, adminToken).body()).path("data");
        assertTrue(containsReport(insideData.path("reports"), reportId), "Report trong khung phải được trả về");

        JsonNode outsideData = mapper.readTree(get("/admin/reports/map?" + outside, adminToken).body()).path("data");
        assertFalse(containsReport(outsideData.path("reports"), reportId), "Report ngoài khung không được trả về");

        rejectReport(adminToken, reportId);
        JsonNode afterReject = mapper.readTree(get("/admin/reports/map?" + inside, adminToken).body()).path("data");
        assertTrue(containsReport(afterReject.path("reports"), reportId),
                "Khác với client, admin vẫn phải thấy report rejected");
    }

    @Test
    @DisplayName("Vượt limit trong khung → cắt bớt và truncated = true")
    void testAdminMap_LimitAndTruncated() throws Exception {
        String clientToken = generateToken("user@gmail.com", "u2", "client");
        String adminToken = generateToken("admin@gmail.com", "u1", "ROLE_admin");

        double[] point = randomPoint();
        createReport(clientToken, point[0], point[1]);
        createReport(clientToken, point[0] + 0.0001, point[1] + 0.0001);

        String inside = boundsQuery(point[0] - 0.0005, point[0] + 0.0005, point[1] - 0.0005, point[1] + 0.0005);
        HttpResponse<String> response = get("/admin/reports/map?limit=1&" + inside, adminToken);
        assertEquals(200, response.statusCode(), response.body());
        JsonNode data = mapper.readTree(response.body()).path("data");
        assertEquals(1, data.path("reports").size(), "Chỉ trả về đúng limit report");
        assertTrue(data.path("truncated").asBoolean(), "Có nhiều report hơn limit → truncated phải là true");
    }
}
