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

public class StaffWalletFlowTest {

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
                .claim("deviceId", "test-device-uuid")
                .claim("tokenType", "access")
                .build();

        SignedJWT signedJWT = new SignedJWT(header, claims);
        signedJWT.sign(new MACSigner(SIGNER_KEY.getBytes(StandardCharsets.UTF_8)));
        return signedJWT.serialize();
    }

    @Test
    @DisplayName("Kiểm thử toàn bộ luồng Ví nhân viên: Tự tạo ví -> Nhận hoa hồng -> Khấu trừ phạt khi đánh giá xấu -> Quản trị cấu hình Admin")
    void testStaffWalletFlow() throws Exception {
        System.out.println("================================================================================");
        System.out.println(">> [TEST STAFF WALLET FLOW] Kiểm thử luồng Ví nhân viên & Hoa hồng");
        System.out.println(">> Target Server : " + BASE_URL);
        System.out.println("================================================================================");

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        ObjectMapper mapper = new ObjectMapper();

        String clientToken = generateToken("user@gmail.com", "u2", "ROLE_client");
        String adminToken = generateToken("admin@gmail.com", "u1", "ROLE_admin");
        String staffToken = generateToken("staff@gmail.com", "u5", "ROLE_staff");

        // -------------------------------------------------------------------------
        // BƯỚC 1: Admin kiểm tra cấu hình hoa hồng mặc định
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 1] Admin lấy cấu hình hoa hồng và tỷ lệ phạt...");
        HttpRequest getConfigReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/admin/wallet/config"))
                .header("Authorization", "Bearer " + adminToken)
                .GET()
                .build();
        HttpResponse<String> getConfigRes = client.send(getConfigReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, getConfigRes.statusCode(), "Lấy cấu hình ví phải trả về 200");
        JsonNode configNode = mapper.readTree(getConfigRes.body()).get("data");
        System.out.println(">> [BƯỚC 1 OK] Cấu hình: Thấp=" + configNode.get("commission_low").asDouble()
                + ", TB=" + configNode.get("commission_medium").asDouble()
                + ", Cao=" + configNode.get("commission_high").asDouble()
                + ", Nghiêm trọng=" + configNode.get("commission_critical").asDouble()
                + ", Phạt L1=" + configNode.get("penalty_rate_1").asDouble() + "%");

        // -------------------------------------------------------------------------
        // BƯỚC 2: Staff gọi GET /staff/wallet để kiểm tra số dư ban đầu
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 2] Staff kiểm tra số dư ví ban đầu...");
        HttpRequest getWalletReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/staff/wallet"))
                .header("Authorization", "Bearer " + staffToken)
                .GET()
                .build();
        HttpResponse<String> getWalletRes = client.send(getWalletReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, getWalletRes.statusCode(), "Lấy thông tin ví phải thành công");
        JsonNode walletNode = mapper.readTree(getWalletRes.body()).get("data");
        double initialBalance = walletNode.get("balance").asDouble();
        System.out.println(">> [BƯỚC 2 OK] Số dư ban đầu của staff: " + initialBalance + " đ");

        // -------------------------------------------------------------------------
        // BƯỚC 3: Client tạo phản ánh sự cố mức 'critical'
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 3] Client tạo phản ánh sự cố mức 'critical'...");
        String createPayload = """
        {
          "title": "Cháy hộp điện tầng 3 nguy cơ chập nổ",
          "description": "Hộp điện tầng 3 phát ra khói và tiếng nổ lách tách.",
          "image_urls": ["https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=800&q=80"],
          "latitude": 10.8507,
          "longitude": 106.7721,
          "is_anonymous": false,
          "address": "Tầng 3 Tòa B",
          "location_description": "Hành lang giữa"
        }
        """;
        HttpRequest createReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + clientToken)
                .POST(HttpRequest.BodyPublishers.ofString(createPayload, StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> createRes = client.send(createReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, createRes.statusCode(), "Tạo report phải thành công");
        String reportId = mapper.readTree(createRes.body()).get("data").get("id").asText();
        System.out.println(">> [BƯỚC 3 OK] Đã tạo report: " + reportId);

        // -------------------------------------------------------------------------
        // BƯỚC 4: Admin phân công phản ánh cho Staff 'u5' với mức 'critical'
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 4] Admin phân công cho staff 'u5' với severity 'critical'...");
        String assignPayload = """
        {
          "staffId": "u5",
          "severity": "critical"
        }
        """;
        HttpRequest assignReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/admin/reports/" + reportId + "/assign"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + adminToken)
                .POST(HttpRequest.BodyPublishers.ofString(assignPayload, StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> assignRes = client.send(assignReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, assignRes.statusCode(), "Phân công report phải thành công");

        // Staff kiểm tra report detail: expected_commission phải là 10000
        HttpRequest detailReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports/" + reportId))
                .header("Authorization", "Bearer " + staffToken)
                .GET()
                .build();
        HttpResponse<String> detailRes = client.send(detailReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        JsonNode detailNode = mapper.readTree(detailRes.body()).get("data");
        assertEquals(10000.0, detailNode.get("expected_commission").asDouble(), "Expected commission phải là 10,000đ");
        System.out.println(">> [BƯỚC 4 OK] Phân công thành công! Expected commission: 10,000đ");

        // -------------------------------------------------------------------------
        // BƯỚC 5: Staff hoàn tất xử lý phản ánh -> Nhận 10,000đ hoa hồng
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 5] Staff hoàn thành phản ánh...");
        String completePayload = """
        {
          "note": "Đã ngắt aptomat và thay thế linh kiện cháy nổ an toàn.",
          "image_urls": ["https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=800&q=80"]
        }
        """;
        HttpRequest completeReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports/" + reportId + "/complete"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + staffToken)
                .POST(HttpRequest.BodyPublishers.ofString(completePayload, StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> completeRes = client.send(completeReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, completeRes.statusCode(), "Complete report phải thành công");

        // Kiểm tra số dư ví Staff sau khi hoàn thành
        HttpResponse<String> walletAfterCompRes = client.send(getWalletReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        JsonNode walletAfterCompNode = mapper.readTree(walletAfterCompRes.body()).get("data");
        double balanceAfterComp = walletAfterCompNode.get("balance").asDouble();
        assertEquals(initialBalance + 10000.0, balanceAfterComp, "Số dư phải tăng đúng 10,000đ");
        System.out.println(">> [BƯỚC 5 OK] Số dư sau khi hoàn thành: " + balanceAfterComp + " đ (+10,000đ)");

        // -------------------------------------------------------------------------
        // BƯỚC 6: Client đánh giá xấu & Admin re-open (Lần 1 -> Trừ 20% = 2,000đ)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 6] Client gửi đánh giá xấu và Admin yêu cầu xử lý lại...");
        String badReviewPayload = """
        {
          "is_resolved": false,
          "reason": "Vẫn còn mùi khét và chưa lắp lại nắp hộp điện.",
          "image_urls": ["https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=800&q=80"]
        }
        """;
        HttpRequest reviewReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports/" + reportId + "/review"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + clientToken)
                .POST(HttpRequest.BodyPublishers.ofString(badReviewPayload, StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> reviewRes = client.send(reviewReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, reviewRes.statusCode(), "Đánh giá xấu phải thành công");

        // Admin gọi API chuyển status về processing
        HttpRequest reopenReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/reports/" + reportId + "/status?newStatus=processing"))
                .header("Authorization", "Bearer " + adminToken)
                .PUT(HttpRequest.BodyPublishers.noBody())
                .build();
        HttpResponse<String> reopenRes = client.send(reopenReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, reopenRes.statusCode(), "Admin re-open phải thành công");

        // Kiểm tra số dư ví Staff sau lần phạt 1: phải bị trừ 2,000đ
        HttpResponse<String> walletAfterPen1Res = client.send(getWalletReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        double balanceAfterPen1 = mapper.readTree(walletAfterPen1Res.body()).get("data").get("balance").asDouble();
        assertEquals(balanceAfterComp - 2000.0, balanceAfterPen1, "Số dư phải bị trừ 20% (2,000đ)");
        System.out.println(">> [BƯỚC 6 OK] Số dư sau khi bị trừ phạt Lần 1: " + balanceAfterPen1 + " đ (-2,000đ)");

        // -------------------------------------------------------------------------
        // BƯỚC 7: Staff hoàn thành lại -> Số dư không được nhận thêm
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 7] Staff hoàn thành lại phản ánh...");
        HttpResponse<String> complete2Res = client.send(completeReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, complete2Res.statusCode(), "Complete report lần 2 phải thành công");

        HttpResponse<String> walletAfterComp2Res = client.send(getWalletReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        double balanceAfterComp2 = mapper.readTree(walletAfterComp2Res.body()).get("data").get("balance").asDouble();
        assertEquals(balanceAfterPen1, balanceAfterComp2, "Hoàn thành lại không được nhận thêm hoa hồng");
        System.out.println(">> [BƯỚC 7 OK] Số dư sau khi xử lý lại giữ nguyên: " + balanceAfterComp2 + " đ");

        // -------------------------------------------------------------------------
        // BƯỚC 8: Kiểm tra lịch sử giao dịch ví (GET /staff/wallet/transactions)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 8] Staff kiểm tra lịch sử giao dịch ví...");
        HttpRequest getTransReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/staff/wallet/transactions?page=0&size=10"))
                .header("Authorization", "Bearer " + staffToken)
                .GET()
                .build();
        HttpResponse<String> getTransRes = client.send(getTransReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, getTransRes.statusCode(), "Lấy lịch sử giao dịch phải thành công");
        JsonNode transPage = mapper.readTree(getTransRes.body()).get("data");
        JsonNode transItems = transPage.get("content");
        assertTrue(transItems.size() >= 2, "Phải có ít nhất 2 giao dịch (COMMISSION và PENALTY_DEDUCTION)");
        System.out.println(">> [BƯỚC 8 OK] Lịch sử giao dịch: Tìm thấy " + transItems.size() + " giao dịch.");

        // -------------------------------------------------------------------------
        // BƯỚC 9: Staff gửi yêu cầu rút tiền (POST /staff/wallet/withdraw)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 9] Staff gửi yêu cầu rút tiền...");
        double withdrawAmount = 50000.0;
        double staffBalanceNow = balanceAfterComp2;
        if (withdrawAmount > staffBalanceNow) {
            withdrawAmount = Math.max(10000.0, staffBalanceNow);
        }

        String withdrawPayload = String.format(java.util.Locale.US, """
        {
          "amount": %.1f,
          "bank_code": "MB",
          "bank_name": "Ngân hàng Quân Đội (MBBank)",
          "bank_account_number": "0987654321",
          "bank_account_name": "NGUYEN VAN STAFF",
          "note": "Rút tiền hoa hồng tháng này"
        }
        """, withdrawAmount);

        HttpRequest withdrawReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/staff/wallet/withdraw"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + staffToken)
                .POST(HttpRequest.BodyPublishers.ofString(withdrawPayload, StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> withdrawRes = client.send(withdrawReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, withdrawRes.statusCode(), "Yêu cầu rút tiền phải thành công: " + withdrawRes.body());
        JsonNode withdrawNode = mapper.readTree(withdrawRes.body()).get("data");
        String withdrawalId = withdrawNode.get("id").asText();
        assertNotNull(withdrawNode.get("qr_code_url").asText(), "Phải sinh ra link VietQR");
        assertTrue(withdrawNode.get("qr_code_url").asText().contains("vietqr.io"), "Link QR phải chứa domain vietqr.io");
        System.out.println(">> [BƯỚC 9 OK] Đã tạo yêu cầu rút tiền: " + withdrawalId + ", VietQR: " + withdrawNode.get("qr_code_url").asText());

        // -------------------------------------------------------------------------
        // BƯỚC 10: Admin kiểm tra số yêu cầu rút tiền chờ duyệt (GET /admin/wallet/withdrawals/pending-count)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 10] Admin kiểm tra số yêu cầu rút tiền chờ duyệt...");
        HttpRequest countReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/admin/wallet/withdrawals/pending-count"))
                .header("Authorization", "Bearer " + adminToken)
                .GET()
                .build();
        HttpResponse<String> countRes = client.send(countReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, countRes.statusCode(), "Lấy pending count phải thành công");
        long pendingCount = mapper.readTree(countRes.body()).get("data").asLong();
        assertTrue(pendingCount >= 1, "Số yêu cầu chờ duyệt phải >= 1");
        System.out.println(">> [BƯỚC 10 OK] Số yêu cầu rút tiền chờ duyệt: " + pendingCount);

        // -------------------------------------------------------------------------
        // BƯỚC 11: Admin lấy danh sách ví nhân viên (GET /admin/wallet/staffs)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 11] Admin lấy danh sách ví nhân viên...");
        HttpRequest adminStaffsReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/admin/wallet/staffs?page=1&size=10"))
                .header("Authorization", "Bearer " + adminToken)
                .GET()
                .build();
        HttpResponse<String> adminStaffsRes = client.send(adminStaffsReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, adminStaffsRes.statusCode(), "Lấy danh sách ví nhân viên phải thành công");
        JsonNode adminStaffsNode = mapper.readTree(adminStaffsRes.body()).get("data");
        assertTrue(adminStaffsNode.get("content").size() > 0, "Danh sách ví nhân viên phải có dữ liệu");
        System.out.println(">> [BƯỚC 11 OK] Tìm thấy " + adminStaffsNode.get("content").size() + " ví nhân viên.");

        // -------------------------------------------------------------------------
        // BƯỚC 12: Admin lấy danh sách yêu cầu rút tiền (GET /admin/wallet/withdrawals)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 12] Admin lấy danh sách yêu cầu rút tiền...");
        HttpRequest adminWithdrawalsReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/admin/wallet/withdrawals?status=PENDING&page=1&size=10"))
                .header("Authorization", "Bearer " + adminToken)
                .GET()
                .build();
        HttpResponse<String> adminWithdrawalsRes = client.send(adminWithdrawalsReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, adminWithdrawalsRes.statusCode(), "Lấy danh sách yêu cầu rút tiền phải thành công");
        JsonNode withdrawalItems = mapper.readTree(adminWithdrawalsRes.body()).get("data").get("content");
        assertTrue(withdrawalItems.size() > 0, "Phải có yêu cầu rút tiền PENDING");
        System.out.println(">> [BƯỚC 12 OK] Danh sách yêu cầu rút tiền có " + withdrawalItems.size() + " bản ghi.");

        // -------------------------------------------------------------------------
        // BƯỚC 13: Admin duyệt chuyển tiền (PUT /admin/wallet/withdrawals/{id}/process)
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 13] Admin duyệt chuyển tiền cho yêu cầu rút tiền...");
        String processPayload = """
        {
          "status": "APPROVED",
          "admin_note": "Đã chuyển khoản qua app ngân hàng MB"
        }
        """;
        HttpRequest processReq = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + "/admin/wallet/withdrawals/" + withdrawalId + "/process"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + adminToken)
                .PUT(HttpRequest.BodyPublishers.ofString(processPayload, StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> processRes = client.send(processReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        assertEquals(200, processRes.statusCode(), "Admin duyệt rút tiền phải thành công: " + processRes.body());
        JsonNode processedData = mapper.readTree(processRes.body()).get("data");
        assertEquals("APPROVED", processedData.get("status").asText(), "Trạng thái phải là APPROVED");
        System.out.println(">> [BƯỚC 13 OK] Duyệt yêu cầu rút tiền thành công!");

        // -------------------------------------------------------------------------
        // BƯỚC 14: Kiểm tra số dư ví Staff sau khi rút tiền
        // -------------------------------------------------------------------------
        System.out.println("\n>> [BƯỚC 14] Kiểm tra số dư ví Staff sau khi trừ tiền rút...");
        HttpResponse<String> walletAfterWithRes = client.send(getWalletReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        double finalBalance = mapper.readTree(walletAfterWithRes.body()).get("data").get("balance").asDouble();
        assertEquals(staffBalanceNow - withdrawAmount, finalBalance, "Số dư phải bị trừ đúng số tiền đã rút");
        System.out.println(">> [BƯỚC 14 OK] Số dư sau khi rút tiền: " + finalBalance + " đ (-" + withdrawAmount + "đ)");

        System.out.println("\n================================================================================");
        System.out.println(">> [KẾT QUẢ KIỂM THỬ] TẤT CẢ CÁC BƯỚC TEST VÍ NHÂN VIÊN ĐỀU THÀNH CÔNG RỰC RỠ!");
        System.out.println("================================================================================");
    }
}

