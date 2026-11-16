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
import java.util.Locale;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Integration test cho nhờ làm giùm (staff delegation). Yêu cầu backend đang chạy tại BASE_URL.
 * Người nhờ: staff u5 — người làm giùm: staff u6.
 */
public class StaffDelegationTest {

    private static final String BASE_URL = "http://localhost:8989";
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";
    private static final String REQUESTER = "u5";
    private static final String HELPER = "u6";

    private static final HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
    private static final ObjectMapper mapper = new ObjectMapper();

    private static String adminToken;
    private static String clientToken;
    private static String requesterToken;
    private static String helperToken;

    @BeforeAll
    static void setup() throws Exception {
        try {
            System.setOut(new PrintStream(System.out, true, StandardCharsets.UTF_8.name()));
        } catch (Exception ignored) {
        }
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("localhost", 8989), 1500);
        } catch (Exception e) {
            fail("[LỖI] Backend chưa được khởi chạy tại " + BASE_URL + "! Vui lòng bật backend trước khi chạy test.");
        }
        adminToken = token("admin@gmail.com", "u1", "ROLE_admin");
        clientToken = token("user@gmail.com", "u2", "ROLE_client");
        requesterToken = token("staff1@gmail.com", REQUESTER, "ROLE_staff");
        helperToken = token("staff2@gmail.com", HELPER, "ROLE_staff");
    }

    // ===================== Helpers =====================

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
        jwt.sign(new MACSigner(SIGNER_KEY.getBytes(StandardCharsets.UTF_8)));
        return jwt.serialize();
    }

    private HttpResponse<String> send(String method, String path, String token, String body) throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + path))
                .header("Content-Type", "application/json")
                .method(method, body == null ? HttpRequest.BodyPublishers.noBody()
                        : HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8));
        if (token != null) builder.header("Authorization", "Bearer " + token);
        return client.send(builder.build(), HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
    }

    private JsonNode okData(HttpResponse<String> response, String step) throws Exception {
        assertEquals(200, response.statusCode(), step + " phải trả 200: " + response.body());
        return mapper.readTree(response.body()).path("data");
    }

    /** Client tạo report, admin giao cho [staffId] với [severity] → processing. */
    private String createAssignedReport(String staffId, String severity) throws Exception {
        ThreadLocalRandom random = ThreadLocalRandom.current();
        String payload = String.format(Locale.US, """
                {"title": "Delegation test report", "description": "Report tạo bởi StaffDelegationTest",
                 "image_urls": [], "latitude": %f, "longitude": %f, "is_anonymous": false}
                """, 10.70 + random.nextDouble() * 0.2, 106.60 + random.nextDouble() * 0.2);
        String reportId = okData(send("POST", "/reports", clientToken, payload), "Tạo report").path("id").asText();
        okData(send("POST", "/admin/reports/" + reportId + "/assign", adminToken,
                "{\"staffId\": \"" + staffId + "\", \"severity\": \"" + severity + "\"}"), "Admin phân công");
        return reportId;
    }

    private HttpResponse<String> complete(String reportId, String token) throws Exception {
        return send("POST", "/reports/" + reportId + "/complete", token,
                "{\"note\": \"StaffDelegationTest hoàn tất\", \"image_urls\": []}");
    }

    private JsonNode state(String reportId, String token) throws Exception {
        return okData(send("GET", "/staff/delegations/report/" + reportId, token, null), "Xem trạng thái nhờ");
    }

    private HttpResponse<String> requestDelegation(String reportId, String helperId) throws Exception {
        return send("POST", "/staff/delegations", requesterToken,
                "{\"report_id\": \"" + reportId + "\", \"helper_id\": \"" + helperId + "\", \"note\": \"Nhờ giúp\"}");
    }

    /** Report (mức thấp) của người nhờ, sẵn sàng nhờ làm giùm. */
    private String reportReadyToDelegate() throws Exception {
        String reportId = createAssignedReport(REQUESTER, "low");
        assertTrue(state(reportId, requesterToken).path("can_request").asBoolean(), "Người nhờ phải nhờ được");
        return reportId;
    }

    // ===================== Tests =====================

    @Test
    @DisplayName("Luồng chính: gửi yêu cầu → nhận → người làm giùm hoàn tất; người nhờ không tự hoàn tất được")
    void testDelegation_HappyPath() throws Exception {
        String reportId = reportReadyToDelegate();

        JsonNode created = okData(requestDelegation(reportId, HELPER), "Gửi yêu cầu nhờ");
        assertEquals("PENDING", created.path("status").asText());

        assertEquals(400, requestDelegation(reportId, HELPER).statusCode(), "Không tạo được 2 yêu cầu cho cùng task");

        String delegationId = created.path("id").asText();
        JsonNode accepted = okData(send("POST", "/staff/delegations/" + delegationId + "/accept", helperToken, null), "Nhận làm giùm");
        assertEquals("ACCEPTED", accepted.path("status").asText());
        assertEquals("ACCEPTED", state(reportId, requesterToken).path("active_delegation").path("status").asText(),
                "Người nhờ vẫn thấy yêu cầu đang hoạt động");
        assertEquals("REQUESTER", state(reportId, requesterToken).path("viewer_role").asText());
        assertEquals("HELPER", state(reportId, helperToken).path("viewer_role").asText());

        assertEquals(403, complete(reportId, requesterToken).statusCode(), "Người nhờ không còn là người được giao");

        okData(complete(reportId, helperToken), "Người làm giùm hoàn tất");

        JsonNode sent = okData(send("GET", "/staff/delegations?box=sent", requesterToken, null), "Danh sách đã gửi");
        boolean completed = false;
        for (JsonNode d : sent.path("content")) {
            if (delegationId.equals(d.path("id").asText())) completed = "COMPLETED".equals(d.path("status").asText());
        }
        assertTrue(completed, "Yêu cầu phải chuyển sang COMPLETED");

        JsonNode helperState = state(reportId, helperToken);
        assertTrue(helperState.path("active_delegation").isNull() || helperState.path("active_delegation").isMissingNode());
        assertEquals(delegationId, helperState.path("completed_delegation").path("id").asText());
        assertEquals("HELPER", helperState.path("viewer_role").asText());
        assertEquals("REQUESTER", state(reportId, requesterToken).path("viewer_role").asText());
    }

    @Test
    @DisplayName("Từ chối / huỷ / admin phân công lại → đóng yêu cầu nhờ làm giùm")
    void testDelegation_CloseFlows() throws Exception {
        // Từ chối
        String declined = reportReadyToDelegate();
        String id1 = okData(requestDelegation(declined, HELPER), "Gửi yêu cầu").path("id").asText();
        JsonNode d1 = okData(send("POST", "/staff/delegations/" + id1 + "/decline", helperToken, null), "Từ chối");
        assertEquals("DECLINED", d1.path("status").asText());

        // Huỷ, sau đó người được nhờ không nhận được nữa
        String cancelled = reportReadyToDelegate();
        String id2 = okData(requestDelegation(cancelled, HELPER), "Gửi yêu cầu").path("id").asText();
        assertEquals(403, send("POST", "/staff/delegations/" + id2 + "/cancel", helperToken, null).statusCode(),
                "Chỉ người nhờ mới huỷ được");
        okData(send("POST", "/staff/delegations/" + id2 + "/cancel", requesterToken, null), "Huỷ");
        assertEquals(400, send("POST", "/staff/delegations/" + id2 + "/accept", helperToken, null).statusCode(),
                "Yêu cầu đã huỷ không nhận được");

        // Admin phân công lại cho người khác khi đang chờ
        String reassigned = reportReadyToDelegate();
        okData(requestDelegation(reassigned, HELPER), "Gửi yêu cầu");
        okData(send("POST", "/admin/reports/" + reassigned + "/assign", adminToken,
                "{\"staffId\": \"" + HELPER + "\", \"severity\": \"low\"}"), "Admin phân công lại");
        assertTrue(state(reassigned, requesterToken).path("active_delegation").isNull(), "Không còn yêu cầu đang hoạt động");
    }

    @Test
    @DisplayName("Phân quyền & điều kiện: không phải người được giao, nhờ chính mình, client gọi API")
    void testDelegation_Validation() throws Exception {
        String reportId = createAssignedReport(REQUESTER, "low");

        HttpResponse<String> notAssignee = send("POST", "/staff/delegations", helperToken,
                "{\"report_id\": \"" + reportId + "\", \"helper_id\": \"" + REQUESTER + "\"}");
        assertEquals(403, notAssignee.statusCode(), "Không phải người được giao → 403");

        assertEquals(400, requestDelegation(reportId, REQUESTER).statusCode(), "Nhờ chính mình → 400");
        assertEquals(400, send("POST", "/staff/delegations", requesterToken, "{\"report_id\": \"" + reportId + "\"}").statusCode(),
                "Thiếu người được nhờ → 400");
        assertEquals(403, send("GET", "/staff/colleagues", clientToken, null).statusCode(), "Client không gọi được API staff");

        JsonNode colleagues = okData(send("GET", "/staff/colleagues", requesterToken, null), "Danh sách đồng nghiệp");
        for (JsonNode c : colleagues.path("content")) {
            assertNotEquals(REQUESTER, c.path("id").asText(), "Danh sách đồng nghiệp không gồm chính mình");
            assertFalse(c.has("email"), "Không lộ email đồng nghiệp");
        }
    }
}
