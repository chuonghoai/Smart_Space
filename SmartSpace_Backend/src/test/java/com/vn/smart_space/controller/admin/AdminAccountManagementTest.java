package com.vn.smart_space.controller.admin;

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

/**
 * Hội đồng quản trị (/admin/admins). Dựa trên seed_data.sql: u1 = admin, u5 = staff, u2 = client.
 * Chỉ gồm các case không để lại side-effect (không khóa tài khoản thật, không gửi mail thật).
 */
public class AdminAccountManagementTest {

    // Ghi đè bằng -Dsmartspace.baseUrl=http://localhost:<port> khi backend chạy cổng khác
    private static final String BASE_URL = System.getProperty("smartspace.baseUrl", "http://localhost:8989");
    private static final String SIGNER_KEY = "ZpWmdK3rFAkBja/qcNOKJrmWFfhRJPLs5FbFr1xMgJVqk7BbHDYPz5blC3CueakgaikoP4vGkHQqXNqkDd63Yw==";

    private static final HttpClient HTTP = HttpClient.newHttpClient();

    @BeforeAll
    static void checkBackendRunning() {
        URI base = URI.create(BASE_URL);
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(base.getHost(), base.getPort()), 1500);
        } catch (Exception e) {
            fail("[LOI] Backend chua chay tai " + BASE_URL + "! Bat backend truoc khi chay test.");
        }
    }

    // Test Case ID: SMP-175
    // Description: Kiểm tra API GET /admin/admins chỉ trả về danh sách admin kèm summary, currentUser và không lộ staff/client
    @Test
    @DisplayName("Danh sach chi gom admin, co summary va danh dau tai khoan cua chinh minh")
    void testListAdmins_OnlyAdmins() throws Exception {
        HttpResponse<String> res = get("/admin/admins?page=1&size=50", adminToken());

        assertEquals(200, res.statusCode());
        String body = res.body();
        assertTrue(body.contains("\"summary\""), "Phai co summary");
        assertTrue(body.contains("admin@gmail.com"), "Phai co admin u1");
        assertTrue(body.contains("\"currentUser\":true"), "Phai danh dau tai khoan dang goi API");
        assertFalse(body.contains("staff1@gmail.com"), "Khong duoc tra ve staff");
        assertFalse(body.contains("user@gmail.com"), "Khong duoc tra ve client");
    }

    // Test Case ID: SMP-176
    // Description: Kiểm tra API GET /admin/admins tự động giới hạn pageSize tối đa về 50 khi truyền size vượt ngưỡng
    @Test
    @DisplayName("Size vuot gioi han bi gioi han ve 50")
    void testListAdmins_PageSizeClamped() throws Exception {
        HttpResponse<String> res = get("/admin/admins?page=1&size=100000", adminToken());

        assertEquals(200, res.statusCode());
        assertTrue(res.body().contains("\"pageSize\":50"));
    }

    // Test Case ID: SMP-177
    // Description: Kiểm tra Staff và Client bị từ chối 403 khi truy cập API danh sách và cập nhật trạng thái hội đồng quản trị
    @Test
    @DisplayName("Staff va client khong duoc truy cap API hoi dong quan tri")
    void testForbiddenForNonAdmin() throws Exception {
        assertEquals(403, get("/admin/admins", token("staff1@gmail.com", "u5", "ROLE_staff")).statusCode());
        assertEquals(403, get("/admin/admins", token("user@gmail.com", "u2", "ROLE_client")).statusCode());
        assertEquals(403, put("/admin/admins/u1/status", "{\"status\":\"blocked\"}",
                token("user@gmail.com", "u2", "ROLE_client")).statusCode());
    }

    // Test Case ID: SMP-178
    // Description: Kiểm tra Admin không thể tự khóa chính tài khoản của mình qua API PUT /admin/admins/u1/status
    @Test
    @DisplayName("Khong the tu khoa chinh minh")
    void testUpdateStatus_SelfRejected() throws Exception {
        HttpResponse<String> res = put("/admin/admins/u1/status", "{\"status\":\"blocked\"}", adminToken());

        assertEquals(400, res.statusCode());
    }

    // Test Case ID: SMP-179
    // Description: Kiểm tra API cập nhật trạng thái admin trả về 404 khi target là tài khoản staff u5
    @Test
    @DisplayName("Khong khoa duoc staff qua API hoi dong quan tri")
    void testUpdateStatus_StaffNotFound() throws Exception {
        HttpResponse<String> res = put("/admin/admins/u5/status", "{\"status\":\"blocked\"}", adminToken());

        assertEquals(404, res.statusCode());
    }

    // Test Case ID: SMP-180
    // Description: Kiểm tra API cập nhật trạng thái admin trả về 400 khi status không hợp lệ hoặc body rỗng
    @Test
    @DisplayName("Trang thai khong hop le bi tu choi")
    void testUpdateStatus_InvalidStatus() throws Exception {
        assertEquals(400, put("/admin/admins/u5/status", "{\"status\":\"deleted\"}", adminToken()).statusCode());
        assertEquals(400, put("/admin/admins/u5/status", "{}", adminToken()).statusCode());
    }

    // Test Case ID: SMP-181
    // Description: Kiểm tra API tạo admin trả về 400 khi fullName rỗng, email sai định dạng hoặc phone không hợp lệ
    @Test
    @DisplayName("Tao admin voi du lieu khong hop le bi tu choi truoc khi gui mail")
    void testCreate_ValidationErrors() throws Exception {
        assertEquals(400, post("/admin/admins", "{\"fullName\":\"\",\"email\":\"a@b.vn\"}", adminToken()).statusCode());
        assertEquals(400, post("/admin/admins", "{\"fullName\":\"A\",\"email\":\"not-an-email\"}", adminToken()).statusCode());
        assertEquals(400, post("/admin/admins",
                "{\"fullName\":\"A\",\"email\":\"a@b.vn\",\"phone\":\"12ab\"}", adminToken()).statusCode());
    }

    // Test Case ID: SMP-182
    // Description: Kiểm tra API tạo admin trả về 400 khi email trùng với tài khoản admin đã tồn tại
    @Test
    @DisplayName("Tao admin trung email da co tai khoan admin bi tu choi")
    void testCreate_DuplicateEmail() throws Exception {
        HttpResponse<String> res = post("/admin/admins",
                "{\"fullName\":\"Dup\",\"email\":\"admin@gmail.com\"}", adminToken());

        assertEquals(400, res.statusCode());
    }

    // Test Case ID: SMP-183
    // Description: Kiểm tra API GET /admin/activities lọc nhật ký hoạt động theo actorId trả về 200 và trường content
    @Test
    @DisplayName("Loc hoat dong theo actorId")
    void testActivities_FilterByActor() throws Exception {
        HttpResponse<String> res = get("/admin/activities?page=1&size=5&actorId=u1", adminToken());

        assertEquals(200, res.statusCode());
        assertTrue(res.body().contains("\"content\""));
    }

    private static HttpResponse<String> get(String path, String token) throws Exception {
        return send(HttpRequest.newBuilder(URI.create(BASE_URL + path))
                .header("Authorization", "Bearer " + token)
                .GET().build(), "GET " + path);
    }

    private static HttpResponse<String> put(String path, String json, String token) throws Exception {
        return send(HttpRequest.newBuilder(URI.create(BASE_URL + path))
                .header("Authorization", "Bearer " + token)
                .header("Content-Type", "application/json")
                .PUT(HttpRequest.BodyPublishers.ofString(json)).build(), "PUT " + path);
    }

    private static HttpResponse<String> post(String path, String json, String token) throws Exception {
        return send(HttpRequest.newBuilder(URI.create(BASE_URL + path))
                .header("Authorization", "Bearer " + token)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json)).build(), "POST " + path);
    }

    private static HttpResponse<String> send(HttpRequest request, String label) throws Exception {
        HttpResponse<String> res = HTTP.send(request, HttpResponse.BodyHandlers.ofString());
        System.out.println(">> " + label + " → " + res.statusCode());
        return res;
    }

    private static String adminToken() throws Exception {
        return token("admin@gmail.com", "u1", "ROLE_admin");
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
