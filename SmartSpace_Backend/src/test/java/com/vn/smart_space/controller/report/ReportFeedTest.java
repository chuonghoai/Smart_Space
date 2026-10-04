package com.vn.smart_space.controller.report;

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
}
