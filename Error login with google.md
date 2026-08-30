# 1. Executive Summary

Quá trình end-to-end audit chức năng Login with Google đã phát hiện ra **hai lỗi nghiêm trọng (Root Causes)** hoạt động độc lập ở hai tầng khác nhau, dẫn đến hiện tượng giao diện không phản hồi (chớp loading) và lỗi `GetCredentialResponse error`.

Lỗi thứ nhất xảy ra ngay tại Frontend khi Google SDK không thể lấy được Credential do thiếu cấu hình SHA-1 trên Firebase.
Lỗi thứ hai xảy ra khi giao tiếp Frontend ↔ Backend: `AuthInterceptor` vô tình đính kèm Token cũ/hết hạn vào API `/auth/login/google`, khiến Spring Security ở Backend chặn request bằng lỗi 401 (JwtException) mặc dù API này đã được cấu hình `permitAll()`.

---

## 2. Actual Login with Google Flow (Flow thực tế đang bị gián đoạn)

1. T0: User bấm `Login with Google`.
2. T1: `_isLoading = true` (giao diện hiện vòng xoay).
3. T2: Google SDK gọi Google Play Services (Credential Manager).
4. **T3 (Thất bại 1 - Hiện tại):** Credential Manager phát hiện app chưa được cấu hình SHA-1 hợp lệ trên Firebase → Báo lỗi `GetCredentialResponse error` và trả về exception mang mã `canceled`.
5. T4: Lệnh `catch` của Flutter bắt được `canceled` → Lặng lẽ bỏ qua (không set `_error`) và tắt loading (`_isLoading = false`). **Giao diện đứng im.**
6. *(Nếu T3 thành công)* T5: Gọi API `POST /auth/login/google`. `AuthInterceptor` vô tình gắn thêm Header `Authorization: Bearer <token_cũ_trong_máy>`.
7. **T6 (Thất bại 2 - Backend):** Spring Security thấy có JWT token nên đem đi giải mã. Token cũ không hợp lệ → Quăng lỗi `JwtException: Token invalid` và trả về HTTP 401. Controller `/auth/login/google` không bao giờ được gọi.
8. T7: Flutter nhận lỗi 401, không báo lỗi rõ ràng lên UI.

---

## 3. Root Cause Matrix

| Layer | Failure possibility | Evidence | Status | Root cause? |
| --- | --- | --- | --- | --- |
| Google Credential | Credential request fail | Terminal báo `GetCredentialResponse error` và `onCancelled`. File `google-services.json` hoàn toàn **trống mảng oauth_client** (thiếu SHA-1). | **FAILED** | **YES (Root Cause 1)** |
| Flutter HTTP | AuthInterceptor tự gắn Token cũ vào public API | Code `AuthInterceptor` dòng 16 luôn gắn token nếu có. Request Login mang theo token cũ. | **FAILED** | **YES (Root Cause 2)** |
| Backend | Token verification fail | Log `JwtException: Token invalid` xuất hiện khi test API login/google ở các bước trước (CustomJwtDecoder.java:42). | **FAILED** | Trực tiếp do Root Cause 2 |
| Backend | User lookup/create fail | Code `AuthenticationService` xử lý Find/Create rất chuẩn, không thấy lỗi. | PASSED | NO |
| Flutter | Catch block swallows error | Block catch bắt mã `canceled` và không hiện lỗi lên UI. | **FAILED** | Bổ trợ cho Root Cause 1 |

---

## 4. Evidence (Bằng chứng cụ thể)

- **Root Cause 1:** Trong file `android/app/google-services.json` hiện tại, key `"oauth_client": []` đang rỗng. Điều này chứng tỏ Project Firebase chưa hề được khai báo mã SHA-1 của Android App, khiến Credential Manager từ chối cấp phát token.
- **Root Cause 2:** File `smartspace_client/lib/core/interceptors/auth_interceptor.dart` (dòng 16-18) tự động nhét `Authorization: Bearer` vào mọi request miễn là máy còn lưu token. Khi Frontend gọi `/auth/login/google` bằng Dio, token rác/cũ bị gửi theo.
- **Root Cause 2 (Backend):** Ở Spring Boot, dù `/auth/login/google` nằm trong `PUBLIC_ENDPOINTS` của `SecurityConfig.java`, nhưng cơ chế filter của `oauth2ResourceServer` vẫn sẽ kích hoạt giải mã JWT nếu Header `Authorization` tồn tại. Nếu token hết hạn, nó quăng `JwtException` (đã thấy ở console log trước đó) và request bị văng ra 401 ngay lập tức.

---

## 5. Implementation Plan (Kế hoạch khắc phục)

### 1. Fix Root Cause 2: Sửa lỗi AuthInterceptor (Frontend)
- **File:** `lib/core/interceptors/auth_interceptor.dart`
- **Current behavior:** Gắn Auth header vào mọi API.
- **Required change:** Chặn (Bypass) không gắn token đối với các API public như `/auth/login`, `/auth/login/google`, `/auth/register`...
- **Why:** Các API xác thực không bao giờ được gửi kèm token cũ để tránh Backend bối rối và kích hoạt bộ lọc bảo mật sai.

### 2. Sửa lỗi Diagnostic / Error Handling (Frontend)
- **File:** `lib/ui/mobile/auth/login/login_controller.dart`
- **Current behavior:** Lỗi `canceled` bị nuốt không dấu vết (giao diện không phản hồi).
- **Required change:** Hiện một dòng SnackBar hoặc cập nhật `_error` nhẹ nhàng: *"Đăng nhập Google bị hủy hoặc chưa cấu hình đúng"*, và thêm `debugPrint` log rõ ràng các mốc (Google Picker Opened, Token Received, v.v.).

### 3. Hướng dẫn Fix Root Cause 1 (Cấu hình Firebase)
- **Vấn đề cấu hình:** Bạn bắt buộc phải vào Firebase Console, mục Project Settings > Android App > Thêm mã SHA-1 (và SHA-256) của máy tính bạn vào, sau đó tải lại file `google-services.json` chép đè vào `android/app`. Không có code nào fix được lỗi thiếu cấu hình SHA-1 trên Server của Google.
- **Action:** Yêu cầu người dùng (User Review) thực hiện cấu hình này.

> [!IMPORTANT]
> **Yêu cầu review & Action từ bạn:**
> Bạn cần thêm SHA-1 vào Firebase Console và tải lại `google-services.json`. Đồng thời, vui lòng xác nhận để tôi bắt đầu triển khai code fix cho `AuthInterceptor` và `LoginController` trên Frontend.
