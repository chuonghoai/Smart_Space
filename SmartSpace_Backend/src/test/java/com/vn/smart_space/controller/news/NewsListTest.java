package com.vn.smart_space.controller.news;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import org.junit.jupiter.api.AfterAll;
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
import java.time.LocalDate;
import java.util.Date;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Integration test danh sách tin tức: GET /news?page=&size=&search=&from=&to=.
 */
public class NewsListTest {

    private static final String BASE_URL = System.getProperty("smartspace.baseUrl", "http://localhost:8989");
    private static final HttpClient HTTP = HttpClient.newHttpClient();
    private static final ObjectMapper MAPPER = new ObjectMapper();
    /** Mã riêng trong tiêu đề để chỉ tin do test tạo khớp từ khoá. */
    private static final String MARKER = "newslisttest"
            + UUID.randomUUID().toString().replace("-", "").substring(0, 10);

    private static String adminToken;
    private static String clientToken;
    private static String createdNewsId;

    @BeforeAll
    static void setUp() throws Exception {
        URI base = URI.create(BASE_URL);
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(base.getHost(), base.getPort()), 1500);
        } catch (Exception e) {
            fail("[LOI] Backend chua chay tai " + BASE_URL + "! Bat backend truoc khi chay test.");
        }
        adminToken = token("admin-test-id", "admin@smartspace.vn", "admin");
        clientToken = token("client-test-id", "client@smartspace.vn", "client");

        String body = """
                {"title": "Tin thu nghiem %s", "content": "Noi dung tin thu nghiem phan trang", "image_urls": []}
                """.formatted(MARKER);
        HttpResponse<String> res = HTTP.send(HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/news"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + adminToken)
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build(), HttpResponse.BodyHandlers.ofString());
        assertEquals(201, res.statusCode(), res.body());
        createdNewsId = MAPPER.readTree(res.body()).path("data").path("id").asText();
    }

    @AfterAll
    static void tearDown() throws Exception {
        if (createdNewsId == null || createdNewsId.isEmpty()) {
            return;
        }
        HTTP.send(HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/news/" + createdNewsId))
                .header("Authorization", "Bearer " + adminToken)
                .DELETE()
                .build(), HttpResponse.BodyHandlers.ofString());
    }

    @Test
    @DisplayName("Mac dinh: trang 1, 10 tin, dang PageResponse, moi nhat truoc")
    void testDefaultPage() throws Exception {
        JsonNode data = data("/news");
        assertEquals(1, data.path("currentPage").asInt());
        assertEquals(10, data.path("pageSize").asInt());
        assertTrue(data.path("totalElements").asLong() >= 1, "Phai co it nhat tin do test tao");

        JsonNode content = data.path("content");
        assertTrue(content.isArray());
        assertTrue(content.size() <= 10);
        for (int i = 1; i < content.size(); i++) {
            String prev = content.get(i - 1).path("created_at").asText();
            String curr = content.get(i).path("created_at").asText();
            assertTrue(prev.compareTo(curr) >= 0, "Khong sap moi nhat truoc tai vi tri " + i);
        }
    }

    @Test
    @DisplayName("Phan trang: size duoc ton trong, size qua lon bi chan o 50, page < 1 ve trang 1")
    void testPaging() throws Exception {
        JsonNode one = data("/news?page=1&size=1");
        assertTrue(one.path("content").size() <= 1);
        assertEquals(one.path("totalElements").asLong(), one.path("totalPages").asLong(),
                "size=1 thi so trang bang so tin");

        assertEquals(50, data("/news?size=500").path("pageSize").asInt());
        assertEquals(1, data("/news?page=0").path("currentPage").asInt());
    }

    @Test
    @DisplayName("Tim kiem theo tieu de: chi tra tin khop tu khoa (khong phan biet hoa thuong)")
    void testSearch() throws Exception {
        JsonNode content = data("/news?search=" + URLEncoder.encode(MARKER.toUpperCase(), StandardCharsets.UTF_8))
                .path("content");
        assertEquals(1, content.size(), "Chi tin do test tao chua ma " + MARKER);
        assertEquals(createdNewsId, content.get(0).path("id").asText());
    }

    @Test
    @DisplayName("Loc theo ngay: hom nay co tin vua tao, ngay mai thi khong")
    void testDateRange() throws Exception {
        String keyword = URLEncoder.encode(MARKER, StandardCharsets.UTF_8);
        LocalDate today = LocalDate.now();
        assertEquals(1, data("/news?search=" + keyword + "&from=" + today + "&to=" + today).path("content").size());

        LocalDate tomorrow = today.plusDays(1);
        assertEquals(0, data("/news?search=" + keyword + "&from=" + tomorrow + "&to=" + tomorrow)
                .path("content").size());
    }

    @Test
    @DisplayName("Gia tri khong hop le bi bo qua, khong loi 500")
    void testInvalidParamsIgnored() throws Exception {
        HttpResponse<String> res = get("/news?from=not-a-date&to=2026-13-45&search=" + "a".repeat(500));
        assertEquals(200, res.statusCode(), res.body());
        assertTrue(MAPPER.readTree(res.body()).path("data").path("content").isArray());
    }

    private static JsonNode data(String path) throws Exception {
        HttpResponse<String> res = get(path);
        assertEquals(200, res.statusCode(), res.body());
        return MAPPER.readTree(res.body()).path("data");
    }

    private static HttpResponse<String> get(String path) throws Exception {
        return HTTP.send(HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + path))
                .header("Authorization", "Bearer " + clientToken)
                .GET()
                .build(), HttpResponse.BodyHandlers.ofString());
    }

    private static String token(String userId, String email, String role) throws Exception {
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .subject(userId)
                .claim("userId", userId)
                .claim("email", email)
                .claim("scope", "ROLE_" + role)
                .issueTime(new Date())
                .expirationTime(new Date(System.currentTimeMillis() + 3600_000))
                .jwtID(UUID.randomUUID().toString())
                .build();
        SignedJWT jwt = new SignedJWT(new JWSHeader(JWSAlgorithm.HS512), claims);
        // jwt.sign(new MACSigner(SIGNER_KEY.getBytes(StandardCharsets.UTF_8)));
        return jwt.serialize();
    }
}
