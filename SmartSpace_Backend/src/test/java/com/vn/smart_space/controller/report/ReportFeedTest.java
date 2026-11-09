package com.vn.smart_space.controller.report;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/** Client (u2) reads the public feed: no rejected reports, no phone, no identity on anonymous posts. */
public class ReportFeedTest {

    private static final String BASE_URL = "http://localhost:8989";
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";

    @BeforeAll
    static void checkBackendRunning() {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("localhost", 8989), 1500);
        } catch (Exception e) {
            fail("[LOI] Backend chua chay tai " + BASE_URL + "! Bat backend truoc khi chay test.");
        }
    }

    @Test
    @DisplayName("Client xem Bang tin: khong co rejected, khong lo SDT, an danh khong lo ten")
    void testFeed_PublicSafety() throws Exception {
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .subject("user@gmail.com")
                .issuer("smartspace.vn")
                .issueTime(new Date())
                .expirationTime(new Date(System.currentTimeMillis() + 3600_000))
                .jwtID(UUID.randomUUID().toString())
                .claim("scope", "ROLE_client")
                .claim("userId", "u2")
                .claim("deviceId", "test-device-uuid")
                .claim("tokenType", "access")
                .build();
        SignedJWT jwt = new SignedJWT(new JWSHeader(JWSAlgorithm.HS512), claims);
        jwt.sign(new MACSigner(SIGNER_KEY.getBytes()));

        HttpResponse<String> res = HttpClient.newHttpClient().send(
                HttpRequest.newBuilder(URI.create(BASE_URL + "/reports/feed?page=1&size=20"))
                        .header("Authorization", "Bearer " + jwt.serialize())
                        .GET().build(),
                HttpResponse.BodyHandlers.ofString());

        System.out.println(">> Status: " + res.statusCode());
        System.out.println(">> Body: " + res.body());
        assertEquals(200, res.statusCode());
        String body = res.body();
        assertTrue(body.contains("\"content\""), "Phai tra ve PageResponse");
        assertFalse(body.contains("\"status\":\"rejected\""), "Khong duoc tra ve phan anh bi tu choi");
        assertFalse(body.matches("(?s).*\"user_phone\":\"[^\"]+\".*"), "Khong duoc lo SDT nguoi gui");
        assertFalse(body.matches("(?s).*\"assigned_staff_email\":\"[^\"]+\".*"), "Khong duoc lo email nhan vien");
        assertFalse(body.matches("(?s).*\"is_anonymous\":true[^}]*\"user_name\":\"[^\"]+\".*"),
                "Phan anh an danh khong duoc lo ten");
    }

    @Test
    @DisplayName("Gan toi: backend sap xep theo khoang cach, dung thu tu ca khi sang trang 2")
    void testFeed_NearbySortedAcrossPages() throws Exception {
        String base = "/reports/feed?sort=nearby&user_lat=10.7769&user_long=106.7009&size=5&page=";
        List<Double> distances = new ArrayList<>();
        for (int page = 1; page <= 2; page++) {
            for (JsonNode item : content(get(base + page))) {
                assertTrue(item.hasNonNull("distance_in_meters"), "Gan toi phai co khoang cach");
                distances.add(item.get("distance_in_meters").asDouble());
            }
        }
        for (int i = 1; i < distances.size(); i++) {
            // Sai so nho cua phep xap xi equirectangular so voi haversine o cu ly thanh pho
            assertTrue(distances.get(i) + 1.0 >= distances.get(i - 1),
                    "Khoang cach phai khong giam: " + distances);
        }
    }

    @Test
    @DisplayName("Loc muc do: chi tra ve phan anh dung severity")
    void testFeed_SeverityFilter() throws Exception {
        for (JsonNode item : content(get("/reports/feed?severity=high&size=20&page=1"))) {
            assertEquals("high", item.get("severity").asText());
        }
    }

    @Test
    @DisplayName("Tim kiem: moi ket qua chua tu khoa trong tieu de, mo ta hoac dia chi")
    void testFeed_SearchMatchesReportContentOnly() throws Exception {
        JsonNode all = content(get("/reports/feed?size=1&page=1"));
        assumeTrue(all.size() > 0, "Can it nhat 1 phan anh trong Bang tin");
        String title = all.get(0).get("title").asText();
        String keyword = title.length() > 4 ? title.substring(0, 4) : title;

        JsonNode results = content(get("/reports/feed?size=20&page=1&search="
                + URLEncoder.encode(keyword, StandardCharsets.UTF_8)));
        assertTrue(results.size() > 0, "Tu khoa lay tu tieu de phai co ket qua");
        String needle = keyword.toLowerCase();
        for (JsonNode item : results) {
            String haystack = (item.path("title").asText("") + " " + item.path("description").asText("") + " "
                    + item.path("address").asText("")).toLowerCase();
            assertTrue(haystack.contains(needle), "Ket qua khong chua tu khoa '" + keyword + "': " + item);
        }
    }

    @Test
    @DisplayName("Loc theo ngay: from = to = mot ngay chi tra ve phan anh tao trong dung ngay do")
    void testFeed_SingleDayFilter() throws Exception {
        JsonNode latest = content(get("/reports/feed?size=1&page=1"));
        assumeTrue(latest.size() > 0, "Can it nhat 1 phan anh trong Bang tin");
        String day = latest.get(0).get("created_at").asText().substring(0, 10); // yyyy-MM-dd

        JsonNode results = content(get("/reports/feed?size=20&page=1&from=" + day + "&to=" + day));
        assertTrue(results.size() > 0, "Ngay cua phan anh moi nhat phai co ket qua");
        for (JsonNode item : results) {
            assertTrue(item.get("created_at").asText().startsWith(day),
                    "Phan anh ngoai ngay " + day + ": " + item.get("created_at").asText());
        }
    }

    private static String clientToken() throws Exception {
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .subject("user@gmail.com")
                .issuer("smartspace.vn")
                .issueTime(new Date())
                .expirationTime(new Date(System.currentTimeMillis() + 3600_000))
                .jwtID(UUID.randomUUID().toString())
                .claim("scope", "ROLE_client")
                .claim("userId", "u2")
                .claim("deviceId", "test-device-uuid")
                .claim("tokenType", "access")
                .build();
        SignedJWT jwt = new SignedJWT(new JWSHeader(JWSAlgorithm.HS512), claims);
        jwt.sign(new MACSigner(SIGNER_KEY.getBytes()));
        return jwt.serialize();
    }

    private static String get(String path) throws Exception {
        HttpResponse<String> res = HttpClient.newHttpClient().send(
                HttpRequest.newBuilder(URI.create(BASE_URL + path))
                        .header("Authorization", "Bearer " + clientToken())
                        .GET().build(),
                HttpResponse.BodyHandlers.ofString());
        assertEquals(200, res.statusCode(), "GET " + path + " -> " + res.body());
        return res.body();
    }

    private static JsonNode content(String body) throws Exception {
        return new ObjectMapper().readTree(body).path("data").path("content");
    }
}
