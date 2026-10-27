package com.vn.smart_space.controller.report;

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

public class NearbyReportsAlertTest {

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
            System.err.println("================================================================================");
            System.err.println(">> [LỖI NGHIÊM TRỌNG] Backend chưa được khởi chạy tại " + BASE_URL + "!");
            System.err.println(">> Vui lòng chạy backend (ví dụ: 'npm run backend:dev') trên một terminal riêng.");
            System.err.println("================================================================================");
            fail("[LỖI] Backend chưa được khởi chạy tại " + BASE_URL + "! Vui lòng bật backend trước khi chạy test.");
        }
    }

    @Test
    @DisplayName("Mô phỏng Client gọi API kiểm tra phản ánh trong bán kính 200m để cảnh báo (gọi API 1 lần duy nhất)")
    void testCheckNearbyAlerts_SimulateRealClient() throws Exception {
        // 1. Tạo JWT Bearer Token hợp lệ cho Client
        Date issueTime = new Date();
        Date expiryTime = new Date(System.currentTimeMillis() + 3600_000);
        JWSHeader header = new JWSHeader(JWSAlgorithm.HS512);
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .subject("client.test@smartspace.vn")
                .issuer("smartspace.vn")
                .issueTime(issueTime)
                .expirationTime(expiryTime)
                .jwtID(UUID.randomUUID().toString())
                .claim("scope", "client")
                .claim("userId", "u2")
                .claim("deviceId", "test-device-client-1")
                .claim("tokenType", "access")
                .build();

        SignedJWT signedJWT = new SignedJWT(header, claims);
        signedJWT.sign(new MACSigner(SIGNER_KEY.getBytes(StandardCharsets.UTF_8)));
        String bearerToken = signedJWT.serialize();

        // 2. Tọa độ kiểm tra (Ví dụ: Đại học Sư phạm Kỹ thuật TP.HCM)
        double userLat = 10.8505;
        double userLng = 106.7719;
        double radius = 200.0;

        String endpoint = String.format("%s/reports/nearby-alerts?lat=%.4f&lng=%.4f&radius=%.1f",
                BASE_URL, userLat, userLng, radius);

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(endpoint))
                .timeout(Duration.ofSeconds(10))
                .header("Authorization", "Bearer " + bearerToken)
                .header("Accept", "application/json")
                .GET()
                .build();

        System.out.println(">> Gửi request GET: " + endpoint);

        // 3. Thực thi request
        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

        System.out.println(">> Phản hồi status: " + response.statusCode());
        System.out.println(">> Body: " + response.body());

        // 4. Assertions
        assertEquals(200, response.statusCode(), "Phản hồi API phải trả về mã trạng thái 200 OK");
        assertNotNull(response.body(), "Response body không được rỗng");
        assertTrue(response.body().contains("\"success\":true"), "Response phải có success: true");
        assertTrue(response.body().contains("\"count\""), "Response phải có trường count");
        assertTrue(response.body().contains("\"reports\""), "Response phải có danh sách reports");
    }
}
