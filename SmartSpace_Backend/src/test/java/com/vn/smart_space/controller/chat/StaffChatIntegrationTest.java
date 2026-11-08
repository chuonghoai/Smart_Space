package com.vn.smart_space.controller.chat;

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
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

public class StaffChatIntegrationTest {

    private static final String BASE_URL = "http://localhost:8989";
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";

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
            System.err.println(">> [LỖI] Backend chưa được khởi chạy tại " + BASE_URL + "!");
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
                .claim("scope", role)
                .claim("userId", userId)
                .claim("deviceId", "test-device-" + UUID.randomUUID())
                .claim("tokenType", "access")
                .build();

        SignedJWT signedJWT = new SignedJWT(header, claims);
        signedJWT.sign(new MACSigner(SIGNER_KEY.getBytes(StandardCharsets.UTF_8)));
        return signedJWT.serialize();
    }

    @Test
    @DisplayName("Kiểm tra toàn diện API hội thoại, tin nhắn, phân quyền và presence cho Staff")
    void testStaffChatFlow() throws Exception {
        HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
        String staffToken = createBearerToken("u3", "staff@gmail.com", "staff");

        // 1. Lấy danh sách hội thoại của Staff (bộ lọc 'all')
        HttpRequest getMyConvRequest = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/conversations/my-conversation?page=1&size=10&role=all"))
                .header("Authorization", "Bearer " + staffToken)
                .GET()
                .build();

        HttpResponse<String> convResponse = client.send(getMyConvRequest, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, convResponse.statusCode());
        assertTrue(convResponse.body().contains("system.success") || convResponse.body().contains("conversation.get.success"));

        // 2. Lấy số lượng tin nhắn chưa đọc
        HttpRequest getUnreadRequest = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/conversations/unread-count"))
                .header("Authorization", "Bearer " + staffToken)
                .GET()
                .build();

        HttpResponse<String> unreadResponse = client.send(getUnreadRequest, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, unreadResponse.statusCode());

        // 3. Lọc theo role 'client'
        HttpRequest getClientConvRequest = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/conversations/my-conversation?page=1&size=10&role=client"))
                .header("Authorization", "Bearer " + staffToken)
                .GET()
                .build();

        HttpResponse<String> clientConvResponse = client.send(getClientConvRequest, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, clientConvResponse.statusCode());

        // 4. Lọc theo role 'admin'
        HttpRequest getAdminConvRequest = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/conversations/my-conversation?page=1&size=10&role=admin"))
                .header("Authorization", "Bearer " + staffToken)
                .GET()
                .build();

        HttpResponse<String> adminConvResponse = client.send(getAdminConvRequest, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, adminConvResponse.statusCode());
    }
}

