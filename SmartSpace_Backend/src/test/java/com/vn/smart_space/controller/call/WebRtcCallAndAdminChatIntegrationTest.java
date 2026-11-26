package com.vn.smart_space.controller.call;

import static org.junit.jupiter.api.Assertions.*;

import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Date;
import java.util.UUID;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;

public class WebRtcCallAndAdminChatIntegrationTest {

    private static final String BASE_URL = "http://localhost:8989";
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";

    @BeforeAll
    static void checkBackendRunning() {
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

    private String createBearerToken(String userId, String email, String role) throws Exception {
        Date issueTime = new Date();
        Date expiryTime = new Date(System.currentTimeMillis() + 3600_000);
        JWSHeader header = new JWSHeader(JWSAlgorithm.HS512);
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .subject(email)
                .issuer("smartspace.vn")
                .issueTime(issueTime)
                .expirationTime(expiryTime)
                .jwtID(UUID.randomUUID().toString())
                .claim("scope", "ROLE_" + role)
                .claim("userId", userId)
                .claim("deviceId", "test-device-uuid")
                .claim("tokenType", "access")
                .build();

        SignedJWT signedJWT = new SignedJWT(header, claims);
        signedJWT.sign(new MACSigner(SIGNER_KEY.getBytes(StandardCharsets.UTF_8)));
        return signedJWT.serialize();
    }

    @Test
    @DisplayName("Verify WebRTC ICE servers, Call permission matrix, and Admin-Client eligibility endpoints")
    void testCallAndEligibilityEndpoints() throws Exception {
        HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
        String adminToken = createBearerToken("u1", "admin@gmail.com", "admin");
        String clientToken = createBearerToken("u2", "user@gmail.com", "client");
        String staffToken = createBearerToken("u5", "staff1@gmail.com", "staff");

        // 1. ICE servers endpoint returns STUN config without leaking secrets to unauthenticated callers
        HttpRequest unauthIce = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/calls/ice-servers"))
                .GET()
                .build();
        assertEquals(401, client.send(unauthIce, HttpResponse.BodyHandlers.ofString()).statusCode());

        HttpRequest authIce = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/calls/ice-servers"))
                .header("Authorization", "Bearer " + staffToken)
                .GET()
                .build();
        HttpResponse<String> iceRes = client.send(authIce, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, iceRes.statusCode());
        assertTrue(iceRes.body().contains("\"iceServers\""), "Unexpected ice-servers response: " + iceRes.body());

        // 2. Staff -> Admin call permission must be allowed
        HttpRequest staffToAdmin = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/calls/permission?targetUserId=u1"))
                .header("Authorization", "Bearer " + staffToken)
                .GET()
                .build();
        HttpResponse<String> s2aRes = client.send(staffToAdmin, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, s2aRes.statusCode());
        assertTrue(s2aRes.body().contains("\"allowed\":true"), "Unexpected staff->admin response: " + s2aRes.body());

        // 3. Client -> Client call permission must be denied
        HttpRequest clientToClient = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/calls/permission?targetUserId=u3"))
                .header("Authorization", "Bearer " + clientToken)
                .GET()
                .build();
        HttpResponse<String> c2cRes = client.send(clientToClient, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, c2cRes.statusCode());
        assertTrue(c2cRes.body().contains("\"allowed\":false"), "Unexpected client->client response: " + c2cRes.body());
        assertTrue(
                c2cRes.body().contains("conversation.client_client_forbidden"),
                "Unexpected client->client reason: " + c2cRes.body());

        // 4. Admin -> Client eligibility endpoint responds 200
        HttpRequest adminEligibility = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/conversations/eligibility?targetUserId=u2"))
                .header("Authorization", "Bearer " + adminToken)
                .GET()
                .build();
        HttpResponse<String> eligRes = client.send(adminEligibility, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, eligRes.statusCode());
        assertTrue(eligRes.body().contains("\"canMessage\""), "Unexpected admin eligibility response: " + eligRes.body());
    }
}
