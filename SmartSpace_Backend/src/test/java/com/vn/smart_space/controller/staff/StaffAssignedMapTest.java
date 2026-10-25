package com.vn.smart_space.controller.staff;

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
 * Integration test cho contract mà bản đồ Staff dùng:
 * GET /reports/staff/assigned?status=processing&limit=100.
 * Yêu cầu backend đang chạy và dữ liệu seed (staff u5).
 */
public class StaffAssignedMapTest {

    private static final String BASE_URL = System.getProperty("smartspace.baseUrl", "http://localhost:8989");
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";
    private static final HttpClient HTTP = HttpClient.newHttpClient();
    private static final ObjectMapper MAPPER = new ObjectMapper();

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
    @DisplayName("Khong co token → 401")
    void testUnauthorized() throws Exception {
        assertEquals(401, get("/reports/staff/assigned?status=processing&limit=100", null).statusCode());
    }

    @Test
    @DisplayName("status=processing: chi tra viec dang xu ly cua staff, du truong cho ban do")
    void testProcessingContractForMap() throws Exception {
        HttpResponse<String> res = get("/reports/staff/assigned?status=processing&limit=100",
                token("staff1@gmail.com", "u5", "ROLE_staff"));
        assertEquals(200, res.statusCode(), res.body());

        JsonNode data = MAPPER.readTree(res.body()).path("data");
        assertTrue(data.isArray(), "data phai la mang");
        assertTrue(data.size() <= 100, "Khong vuot qua limit");

        for (JsonNode report : data) {
            assertEquals("processing", report.path("status").asText(), "Chi tra report dang xu ly");
            for (String field : new String[] { "id", "title", "latitude", "longitude", "severity", "imageUrl" }) {
                assertTrue(report.has(field), "Thieu truong " + field + " cho ban do");
            }
            assertTrue(report.has("isReviewResolved"), "Can isReviewResolved de nhan biet viec xu ly lai");
        }
    }

    @Test
    @DisplayName("limit duoc ton trong (gioi han tren cua backend la 100)")
    void testLimitHonored() throws Exception {
        HttpResponse<String> res = get("/reports/staff/assigned?status=processing&limit=1",
                token("staff1@gmail.com", "u5", "ROLE_staff"));
        assertEquals(200, res.statusCode(), res.body());
        assertTrue(MAPPER.readTree(res.body()).path("data").size() <= 1);
    }

    private static HttpResponse<String> get(String path, String token) throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder().uri(URI.create(BASE_URL + path)).GET();
        if (token != null) builder.header("Authorization", "Bearer " + token);
        return HTTP.send(builder.build(), HttpResponse.BodyHandlers.ofString());
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
