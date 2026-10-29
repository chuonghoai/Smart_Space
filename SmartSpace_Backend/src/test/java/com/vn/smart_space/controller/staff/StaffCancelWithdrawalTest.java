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

public class StaffCancelWithdrawalTest {

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
                .claim("deviceId", "test-cancel-withdrawal-device")
                .claim("tokenType", "access")
                .build();

        SignedJWT signedJWT = new SignedJWT(header, claims);
        signedJWT.sign(new MACSigner(SIGNER_KEY.getBytes(StandardCharsets.UTF_8)));
        return signedJWT.serialize();
    }

    @Test
    @DisplayName("Kiểm thử luồng Staff hủy yêu cầu rút tiền: PENDING -> CANCELLED, hoàn lại số dư ví và chặn hủy trùng/chặn trái quyền")
    void testStaffCancelWithdrawalFlow() throws Exception {
        System.out.println("================================================================================");
        System.out.println(">> [TEST STAFF CANCEL WITHDRAWAL] Kiểm thử chức năng Staff Hủy yêu cầu rút tiền");
        System.out.println(">> Target Server : " + BASE_URL);
        System.out.println("================================================================================");

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        ObjectMapper mapper = new ObjectMapper();

        String clientToken = generateToken("user@gmail.com", "u2", "ROLE_client");
        String adminToken = generateToken("admin@gmail.com", "u1", "ROLE_admin");
        String staff1Token = generateToken("staff1@gmail.com", "u5", "ROLE_staff");
        String staff2Token = generateToken("staff2@gmail.com", "u6", "ROLE_staff");

        // -------------------------------------------------------------------------
        // BƯỚC 1: Kiểm tra số dư ví Staff 1, nếu < 10,000đ thì tạo hoa hồng bổ sung
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 1] Lấy số dư ví của Staff 1 (u5)...");
        HttpRequest getWalletReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/staff/wallet"))
                .header("Authorization", "Bearer " + staff1Token)
                .GET()
                .build();
        HttpResponse<String> walletRes = client.send(getWalletReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, walletRes.statusCode(), "Lấy ví nhân viên phải thành công");
        double balance = mapper.readTree(walletRes.body()).get("data").get("balance").asDouble();
        System.out.println(">> [BƯỚC 1 OK] Số dư hiện tại của Staff 1: " + balance + " đ");

        if (balance < 10000.0) {
            System.out.println(">> Số dư < 10,000đ, nạp thêm hoa hồng bằng cách xử lý phản ánh...");
            String reportPayload = """
            {
              "title": "Sự cố test nạp ví để rút tiền",
              "content": "Kiểm thử hệ thống SmartSpace rút tiền và hủy rút tiền.",
              "location": "Tòa A",
              "latitude": 10.8505,
              "longitude": 106.7718,
              "severity": "LOW",
              "category_id": "cat-electric",
              "images": ["https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=800&q=80"]
            }
            """;
            HttpRequest createReportReq = HttpRequest.newBuilder()
                    .uri(URI.create(BASE_URL + "/reports"))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer " + clientToken)
                    .POST(HttpRequest.BodyPublishers.ofString(reportPayload, StandardCharsets.UTF_8))
                    .build();
            HttpResponse<String> createReportRes = client.send(createReportReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            String repId = mapper.readTree(createReportRes.body()).get("data").get("id").asText();

            HttpRequest assignReq = HttpRequest.newBuilder()
                    .uri(URI.create(BASE_URL + "/reports/" + repId + "/assign?staffId=u5"))
                    .header("Authorization", "Bearer " + adminToken)
                    .PUT(HttpRequest.BodyPublishers.noBody())
                    .build();
            client.send(assignReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

            String compPayload = """
            {
              "staff_note": "Hoàn tất xử lý để test ví",
              "image_urls": ["https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=800&q=80"]
            }
            """;
            HttpRequest compReq = HttpRequest.newBuilder()
                    .uri(URI.create(BASE_URL + "/reports/" + repId + "/complete"))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer " + staff1Token)
                    .PUT(HttpRequest.BodyPublishers.ofString(compPayload, StandardCharsets.UTF_8))
                    .build();
            client.send(compReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

            walletRes = client.send(getWalletReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            balance = mapper.readTree(walletRes.body()).get("data").get("balance").asDouble();
            System.out.println(">> Số dư sau khi hoàn thành phản ánh: " + balance + " đ");
        }

        double initialBalance = balance;
        double withdrawAmount = 10000.0;

        // -------------------------------------------------------------------------
        // BƯỚC 2: Staff 1 tạo yêu cầu rút tiền 10,000đ (POST /staff/wallet/withdraw)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 2] Staff 1 tạo yêu cầu rút tiền 10,000đ...");
        String withdrawPayload = """
        {
          "amount": 10000.0,
          "bank_code": "MB",
          "bank_name": "MBBank - Ngan hang Quan Doi",
          "bank_account_number": "0968714329",
          "bank_account_name": "NGUYEN VAN NHAN VIEN"
        }
        """;
        HttpRequest withdrawReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/staff/wallet/withdraw"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + staff1Token)
                .POST(HttpRequest.BodyPublishers.ofString(withdrawPayload, StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> withdrawRes = client.send(withdrawReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, withdrawRes.statusCode(), "Tạo yêu cầu rút tiền phải thành công: " + withdrawRes.body());
        JsonNode withdrawNode = mapper.readTree(withdrawRes.body()).get("data");
        String withdrawalId = withdrawNode.get("id").asText();
        assertEquals("PENDING", withdrawNode.get("status").asText(), "Trạng thái ban đầu phải là PENDING");
        System.out.println(">> [BƯỚC 2 OK] Đã tạo yêu cầu rút tiền: " + withdrawalId + " (Status: PENDING)");

        // -------------------------------------------------------------------------
        // BƯỚC 3: Kiểm tra số dư ví Staff 1 bị tạm giữ (-10,000đ)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 3] Kiểm tra số dư ví Staff 1 bị trừ tạm giữ...");
        HttpResponse<String> walletAfterWithRes = client.send(getWalletReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        double balanceAfterWith = mapper.readTree(walletAfterWithRes.body()).get("data").get("balance").asDouble();
        assertEquals(initialBalance - withdrawAmount, balanceAfterWith, 0.001, "Số dư phải bị trừ 10,000đ");
        System.out.println(">> [BƯỚC 3 OK] Số dư sau khi tạo yêu cầu rút tiền: " + balanceAfterWith + " đ (-" + withdrawAmount + "đ)");

        // -------------------------------------------------------------------------
        // BƯỚC 4: Chặn nhân viên khác (Staff 2) hủy yêu cầu của Staff 1
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 4] Thử dùng tài khoản Staff 2 để hủy yêu cầu của Staff 1...");
        HttpRequest invalidCancelReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/staff/wallet/withdrawals/" + withdrawalId + "/cancel"))
                .header("Authorization", "Bearer " + staff2Token)
                .POST(HttpRequest.BodyPublishers.noBody())
                .build();
        HttpResponse<String> invalidCancelRes = client.send(invalidCancelReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertTrue(invalidCancelRes.statusCode() == 403 || invalidCancelRes.statusCode() == 400 || invalidCancelRes.statusCode() == 500,
                "Nhân viên khác hủy yêu cầu phải bị từ chối");
        System.out.println(">> [BƯỚC 4 OK] Chặn hủy trái quyền thành công! HTTP Status: " + invalidCancelRes.statusCode());

        // -------------------------------------------------------------------------
        // BƯỚC 5: Staff 1 chính chủ thực hiện hủy yêu cầu rút tiền
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 5] Staff 1 chính chủ gọi API hủy yêu cầu rút tiền...");
        HttpRequest validCancelReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/staff/wallet/withdrawals/" + withdrawalId + "/cancel"))
                .header("Authorization", "Bearer " + staff1Token)
                .POST(HttpRequest.BodyPublishers.noBody())
                .build();
        HttpResponse<String> validCancelRes = client.send(validCancelReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, validCancelRes.statusCode(), "Hủy yêu cầu rút tiền phải thành công: " + validCancelRes.body());
        JsonNode cancelNode = mapper.readTree(validCancelRes.body());
        assertTrue(cancelNode.get("success").asBoolean(), "Response success phải là true");
        assertEquals("CANCELLED", cancelNode.get("data").get("status").asText(), "Trạng thái phải chuyển sang CANCELLED");
        System.out.println(">> [BƯỚC 5 OK] Hủy yêu cầu rút tiền thành công! Trạng thái mới: " + cancelNode.get("data").get("status").asText());

        // -------------------------------------------------------------------------
        // BƯỚC 6: Kiểm tra số dư ví Staff 1 được hoàn lại đầy đủ (+10,000đ)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 6] Kiểm tra số dư ví Staff 1 sau khi hủy và hoàn tiền...");
        HttpResponse<String> walletAfterCancelRes = client.send(getWalletReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        double balanceAfterCancel = mapper.readTree(walletAfterCancelRes.body()).get("data").get("balance").asDouble();
        assertEquals(initialBalance, balanceAfterCancel, 0.001, "Số dư phải được hoàn lại bằng đúng initialBalance");
        System.out.println(">> [BƯỚC 6 OK] Số dư sau khi hoàn tiền: " + balanceAfterCancel + " đ (Đã hoàn lại +" + withdrawAmount + "đ)");

        // -------------------------------------------------------------------------
        // BƯỚC 7: Kiểm tra lịch sử giao dịch ví có giao dịch WITHDRAWAL_REFUND
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 7] Kiểm tra lịch sử giao dịch ví của Staff 1...");
        HttpRequest txReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/staff/wallet/transactions?page=1&size=5"))
                .header("Authorization", "Bearer " + staff1Token)
                .GET()
                .build();
        HttpResponse<String> txRes = client.send(txReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, txRes.statusCode(), "Lấy lịch sử giao dịch phải thành công");
        JsonNode txContent = mapper.readTree(txRes.body()).get("data").get("content");
        assertTrue(txContent.size() > 0, "Lịch sử giao dịch không được rỗng");
        JsonNode latestTx = txContent.get(0);
        assertEquals("WITHDRAWAL_REFUND", latestTx.get("type").asText(), "Loại giao dịch gần nhất phải là WITHDRAWAL_REFUND");
        assertEquals(10000.0, latestTx.get("amount").asDouble(), 0.001, "Số tiền giao dịch hoàn phải là +10,000đ");
        System.out.println(">> [BƯỚC 7 OK] Giao dịch hoàn tiền mới nhất: Type=" + latestTx.get("type").asText() + ", Amount=+" + latestTx.get("amount").asDouble() + "đ");

        // -------------------------------------------------------------------------
        // BƯỚC 8: Thử hủy lại lần nữa -> Chặn vì không còn ở trạng thái PENDING
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 8] Thử hủy lại yêu cầu đã CANCELLED...");
        HttpResponse<String> repeatCancelRes = client.send(validCancelReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertTrue(repeatCancelRes.statusCode() == 400 || repeatCancelRes.statusCode() == 500,
                "Hủy lại yêu cầu đã CANCELLED phải thất bại");
        System.out.println(">> [BƯỚC 8 OK] Chặn hủy lặp lại thành công! HTTP Status: " + repeatCancelRes.statusCode());

        // -------------------------------------------------------------------------
        // BƯỚC 9: Admin kiểm tra danh sách yêu cầu rút tiền với filter CANCELLED
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 9] Admin kiểm tra danh sách yêu cầu rút tiền trạng thái CANCELLED...");
        HttpRequest adminWithdrawalsReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/admin/wallet/withdrawals?status=CANCELLED&page=1&size=10"))
                .header("Authorization", "Bearer " + adminToken)
                .GET()
                .build();
        HttpResponse<String> adminWithdrawalsRes = client.send(adminWithdrawalsReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, adminWithdrawalsRes.statusCode(), "Admin lấy danh sách yêu cầu rút tiền phải thành công");
        JsonNode adminList = mapper.readTree(adminWithdrawalsRes.body()).get("data").get("content");
        boolean foundCancelled = false;
        for (JsonNode item : adminList) {
            if (item.get("id").asText().equals(withdrawalId)) {
                foundCancelled = true;
                assertEquals("CANCELLED", item.get("status").asText());
                break;
            }
        }
        assertTrue(foundCancelled, "Yêu cầu đã hủy phải xuất hiện trong danh sách Admin với trạng thái CANCELLED");
        System.out.println(">> [BƯỚC 9 OK] Admin đã thấy yêu cầu " + withdrawalId + " ở trạng thái CANCELLED!");

        System.out.println("\n================================================================================");
        System.out.println(">> [KẾT QUẢ KIỂM THỬ] TẤT CẢ 9 BƯỚC KIỂM THỬ HỦY YÊU CẦU RÚT TIỀN ĐỀU THÀNH CÔNG RỰC RỠ!");
        System.out.println("================================================================================");
    }
}

