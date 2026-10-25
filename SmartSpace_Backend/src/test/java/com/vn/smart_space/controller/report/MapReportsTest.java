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
 * Integration test cho GET /reports/map (bản đồ Client theo khung nhìn).
 * Yêu cầu backend đang chạy tại BASE_URL.
 */
public class MapReportsTest {

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

    private HttpResponse<String> getMap(String token, double minLat, double maxLat, double minLng, double maxLng,
            Integer limit) throws Exception {
        String query = String.format(Locale.US, "min_lat=%f&max_lat=%f&min_lng=%f&max_lng=%f",
                minLat, maxLat, minLng, maxLng);
        if (limit != null) query += "&limit=" + limit;

        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports/map?" + query))
                .GET();
        if (token != null) builder.header("Authorization", "Bearer " + token);
        return client.send(builder.build(), HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
    }

    private String createReport(String token, double lat, double lng) throws Exception {
        String payload = String.format(Locale.US, """
                {
                  "title": "Map viewport test report",
                  "description": "Report tạo bởi MapReportsTest",
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
    @DisplayName("Không có token → 401")
    void testMapReports_Unauthorized() throws Exception {
        HttpResponse<String> response = getMap(null, 10.7, 10.9, 106.6, 106.8, null);
        assertEquals(401, response.statusCode(), "Gọi /reports/map không có token phải trả về 401");
    }

    @Test
    @DisplayName("Bounds không hợp lệ → 400")
    void testMapReports_InvalidBounds() throws Exception {
        String token = generateToken("user@gmail.com", "u2", "client");

        HttpResponse<String> reversed = getMap(token, 10.9, 10.7, 106.6, 106.8, null);
        assertEquals(400, reversed.statusCode(), "min_lat > max_lat phải trả về 400");

        HttpResponse<String> outOfRange = getMap(token, -95, 10.7, 106.6, 106.8, null);
        assertEquals(400, outOfRange.statusCode(), "Latitude ngoài [-90, 90] phải trả về 400");

        HttpResponse<String> badLng = getMap(token, 10.7, 10.9, 106.6, 190, null);
        assertEquals(400, badLng.statusCode(), "Longitude ngoài [-180, 180] phải trả về 400");
    }

    @Test
    @DisplayName("Chỉ trả report trong khung nhìn, có severity, loại bỏ report rejected")
    void testMapReports_BoundsAndRejectedExcluded() throws Exception {
        String clientToken = generateToken("user@gmail.com", "u2", "client");
        String adminToken = generateToken("admin@gmail.com", "u1", "ROLE_admin");

        double[] point = randomPoint();
        String reportId = createReport(clientToken, point[0], point[1]);

        // Khung nhỏ chứa report
        HttpResponse<String> inside = getMap(clientToken,
                point[0] - 0.0005, point[0] + 0.0005, point[1] - 0.0005, point[1] + 0.0005, null);
        assertEquals(200, inside.statusCode());
        JsonNode insideData = mapper.readTree(inside.body()).path("data");
        assertTrue(insideData.has("truncated"), "Response phải có trường truncated");
        assertTrue(containsReport(insideData.path("reports"), reportId), "Report trong khung phải được trả về");
        assertTrue(insideData.path("reports").get(0).has("severity"), "ReportResponse phải có trường severity");

        // Khung lệch hẳn sang bên cạnh → không chứa report
        HttpResponse<String> outside = getMap(clientToken,
                point[0] + 0.01, point[0] + 0.02, point[1] + 0.01, point[1] + 0.02, null);
        assertEquals(200, outside.statusCode());
        assertFalse(containsReport(mapper.readTree(outside.body()).path("data").path("reports"), reportId),
                "Report ngoài khung không được trả về");

        // Admin từ chối report → biến mất khỏi bản đồ
        HttpRequest rejectRequest = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/admin/reports/" + reportId + "/status"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + adminToken)
                .method("PATCH", HttpRequest.BodyPublishers.ofString("{\"status\": \"rejected\"}"))
                .build();
        HttpResponse<String> rejectResponse = client.send(rejectRequest, HttpResponse.BodyHandlers.ofString());
        assertEquals(200, rejectResponse.statusCode(), "Admin từ chối report phải thành công: " + rejectResponse.body());

        HttpResponse<String> afterReject = getMap(clientToken,
                point[0] - 0.0005, point[0] + 0.0005, point[1] - 0.0005, point[1] + 0.0005, null);
        assertFalse(containsReport(mapper.readTree(afterReject.body()).path("data").path("reports"), reportId),
                "Report rejected không được hiện trên bản đồ");
    }

    @Test
    @DisplayName("Vượt limit → cắt bớt và truncated = true")
    void testMapReports_LimitAndTruncated() throws Exception {
        String clientToken = generateToken("user@gmail.com", "u2", "client");

        double[] point = randomPoint();
        createReport(clientToken, point[0], point[1]);
        createReport(clientToken, point[0] + 0.0001, point[1] + 0.0001);

        HttpResponse<String> response = getMap(clientToken,
                point[0] - 0.0005, point[0] + 0.0005, point[1] - 0.0005, point[1] + 0.0005, 1);
        assertEquals(200, response.statusCode());
        JsonNode data = mapper.readTree(response.body()).path("data");
        assertEquals(1, data.path("reports").size(), "Chỉ trả về đúng limit report");
        assertTrue(data.path("truncated").asBoolean(), "Có nhiều report hơn limit → truncated phải là true");
    }
}
