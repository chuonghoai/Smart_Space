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
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Integration test bộ lọc danh sách "Việc được giao" của Staff:
 * GET /reports/staff/assigned?status=&severity=&search=&from=&to=&sort=.
 * Yêu cầu backend đang chạy và dữ liệu seed (staff u5).
 */
public class StaffAssignedFilterTest {

    private static final String BASE_URL = System.getProperty("smartspace.baseUrl", "http://localhost:8989");
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";
    private static final String PATH = "/reports/staff/assigned";
    private static final List<String> SEVERITY_RANK = List.of("critical", "high", "medium", "low");
    private static final HttpClient HTTP = HttpClient.newHttpClient();
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private static String staffToken;

    @BeforeAll
    static void setUp() throws Exception {
        URI base = URI.create(BASE_URL);
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(base.getHost(), base.getPort()), 1500);
        } catch (Exception e) {
            fail("[LOI] Backend chua chay tai " + BASE_URL + "! Bat backend truoc khi chay test.");
        }
        staffToken = token("staff1@gmail.com", "u5", "ROLE_staff");
    }

    @Test
    @DisplayName("Khong co token → 401")
    void testUnauthorized() throws Exception {
        assertEquals(401, get(PATH + "?severity=high", null).statusCode());
    }

    @Test
    @DisplayName("Khong truyen bo loc moi: van tra ve nhu cu (processing + processed)")
    void testBackwardCompatible() throws Exception {
        for (JsonNode item : data(PATH + "?status=all&limit=50")) {
            String status = item.path("status").asText();
            assertTrue(status.equals("processing") || status.equals("processed"), "Trang thai la: " + status);
        }
    }

    @Test
    @DisplayName("Loc muc do: chi tra ve viec dung severity")
    void testSeverityFilter() throws Exception {
        for (JsonNode item : data(PATH + "?status=all&severity=high&limit=50")) {
            assertEquals("high", item.path("severity").asText());
        }
    }

    @Test
    @DisplayName("rehandling + severity: chi viec dang xu ly bi danh gia chua giai quyet")
    void testRehandlingCombinedWithSeverity() throws Exception {
        for (JsonNode item : data(PATH + "?status=rehandling&severity=critical&limit=50")) {
            assertEquals("processing", item.path("status").asText());
            assertFalse(item.path("isReviewResolved").asBoolean(true), "Phai la viec can xu ly lai");
            assertEquals("critical", item.path("severity").asText());
        }
    }

    @Test
    @DisplayName("Tim kiem: moi ket qua chua tu khoa trong tieu de / mo ta / dia chi")
    void testSearch() throws Exception {
        JsonNode all = data(PATH + "?status=all&limit=50");
        if (all.isEmpty()) {
            return; // staff chua co viec nao trong seed
        }
        String title = all.get(0).path("title").asText();
        String keyword = title.length() > 4 ? title.substring(0, 4) : title;

        JsonNode results = data(PATH + "?status=all&limit=50&search="
                + URLEncoder.encode(keyword, StandardCharsets.UTF_8));
        assertFalse(results.isEmpty(), "Phai tim thay it nhat viec co tieu de '" + title + "'");
        String needle = keyword.toLowerCase(Locale.ROOT);
        for (JsonNode item : results) {
            String haystack = (item.path("title").asText() + " " + item.path("description").asText() + " "
                    + item.path("address").asText()).toLowerCase(Locale.ROOT);
            assertTrue(haystack.contains(needle), "Ket qua khong chua tu khoa: " + item.path("id").asText());
        }
    }

    @Test
    @DisplayName("Loc theo mot ngay: moi ket qua tao trong ngay do")
    void testSingleDayRange() throws Exception {
        JsonNode all = data(PATH + "?status=all&limit=1");
        if (all.isEmpty()) {
            return;
        }
        String day = createdAt(all.get(0)).substring(0, 10); // yyyy-MM-dd
        JsonNode results = data(PATH + "?status=all&limit=50&from=" + day + "&to=" + day);
        assertFalse(results.isEmpty(), "Phai co viec trong ngay " + day);
        for (JsonNode item : results) {
            assertTrue(createdAt(item).startsWith(day), "Viec ngoai ngay " + day + ": " + createdAt(item));
        }
    }

    @Test
    @DisplayName("sort=oldest: ngay tao tang dan; sort=latest: giam dan")
    void testSortByDate() throws Exception {
        JsonNode oldest = data(PATH + "?status=all&limit=50&sort=oldest");
        for (int i = 1; i < oldest.size(); i++) {
            assertTrue(createdAt(oldest.get(i - 1)).compareTo(createdAt(oldest.get(i))) <= 0,
                    "Khong tang dan tai vi tri " + i);
        }
        JsonNode latest = data(PATH + "?status=all&limit=50&sort=latest");
        for (int i = 1; i < latest.size(); i++) {
            assertTrue(createdAt(latest.get(i - 1)).compareTo(createdAt(latest.get(i))) >= 0,
                    "Khong giam dan tai vi tri " + i);
        }
    }

    @Test
    @DisplayName("sort=severity: nghiem trong nhat truoc")
    void testSortBySeverity() throws Exception {
        JsonNode results = data(PATH + "?status=all&limit=50&sort=severity");
        for (int i = 1; i < results.size(); i++) {
            assertTrue(rank(results.get(i - 1)) <= rank(results.get(i)), "Sai thu tu muc do tai vi tri " + i);
        }
    }

    @Test
    @DisplayName("Gia tri bo loc khong hop le bi bo qua, khong loi 500")
    void testInvalidFiltersIgnored() throws Exception {
        String longKeyword = "a".repeat(500);
        HttpResponse<String> res = get(PATH + "?status=xyz&severity=boom&from=not-a-date&to=2026-13-45&sort=random"
                + "&search=" + longKeyword, staffToken);
        assertEquals(200, res.statusCode(), res.body());
        assertTrue(MAPPER.readTree(res.body()).path("data").isArray());
    }

    private static int rank(JsonNode item) {
        int index = SEVERITY_RANK.indexOf(item.path("severity").asText());
        return index < 0 ? SEVERITY_RANK.size() : index;
    }

    private static String createdAt(JsonNode item) {
        return item.has("created_at") ? item.path("created_at").asText() : item.path("createdAt").asText();
    }

    private static JsonNode data(String path) throws Exception {
        HttpResponse<String> res = get(path, staffToken);
        assertEquals(200, res.statusCode(), res.body());
        JsonNode data = MAPPER.readTree(res.body()).path("data");
        assertTrue(data.isArray(), "data phai la mang");
        return data;
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
