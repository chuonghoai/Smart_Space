package com.vn.smart_space.controller.notification;

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

/** Client (u2) lọc danh sách thông báo: Tất cả / Chưa đọc. Cần backend đang chạy. */
public class NotificationFilterTest {

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
    @DisplayName("unread=true: chi tra ve thong bao chua doc, khong nhieu hon so badge")
    void testUnreadOnly() throws Exception {
        JsonNode page = data(get("/notifications/my?page=0&size=50&unread=true"));
        for (JsonNode item : page.path("content")) {
            assertFalse(item.path("isRead").asBoolean(true), "Thong bao da doc lot vao bo loc Chua doc: " + item);
        }
        long badge = data(get("/notifications/unread-count")).path("notifNumber").asLong();
        assertTrue(page.path("totalElements").asLong() <= badge,
                "So thong bao chua doc vuot so badge (" + badge + ")");
    }

    @Test
    @DisplayName("Khong truyen unread: van tra ve ca thong bao da doc (tuong thich nguoc cho Staff/Admin)")
    void testDefaultReturnsAll() throws Exception {
        long all = data(get("/notifications/my?page=0&size=1")).path("totalElements").asLong();
        long unread = data(get("/notifications/my?page=0&size=1&unread=true")).path("totalElements").asLong();
        assertTrue(all >= unread, "Tat ca (" + all + ") phai >= Chua doc (" + unread + ")");
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

    private static JsonNode data(String body) throws Exception {
        return new ObjectMapper().readTree(body).path("data");
    }
}
