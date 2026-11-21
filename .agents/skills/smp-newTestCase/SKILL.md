---
name: smp-newTestCase
description: >-
  Tạo một hoặc nhiều test case thực thi được cho 4 project (Flutter Client, Flutter Admin, Flutter Staff, Spring Boot Backend), mobile_shared và hệ thống Playwright Automation Testing; tự động cấp mã SMP-XXX duy nhất, gắn chú thích mã trong file test, tạo tài liệu chi tiết tại docs/TestCases/SMP-XXX.md, đồng bộ docs/TestCaseList.md và đảm bảo runner Playwright/CI tự động chạy đầy đủ test cũ lẫn test mới.
---

# smp-newTestCase

Mục đích: Chuẩn hóa quy trình tạo mới và quản lý test case có khả năng thực thi thực tế trong toàn bộ hệ thống SmartSpace (Flutter Client, Flutter Admin, Flutter Staff, Spring Boot Backend và package dùng chung `mobile_shared`), đảm bảo truy vết 1-1 giữa mã nguồn test với tài liệu quản lý tập trung.

Skill này hỗ trợ cả **yêu cầu tạo một test case đơn lẻ** và **yêu cầu tạo nhiều test case trong cùng một lần thực hiện**.

> **Phân biệt với các skill test khác:**
> - `smp-createTestCase`: chỉ đọc code và liệt kê ý tưởng/danh sách test case trên hội thoại, không tạo file test hay cập nhật hệ thống `SMP-XXX`.
> - `smp-newTesting`: quy chuẩn kỹ thuật chuyên sâu cho Backend Live HTTP Integration Test (`HttpClient` + `Nimbus JWT` + đăng ký `testapi.ps1`). Khi tạo Backend Live HTTP test theo `smp-newTestCase`, áp dụng đồng thời quy chuẩn kỹ thuật của `smp-newTesting` và quy trình cấp mã + tài liệu `SMP-XXX` của skill này.

---

## Dependencies (Quy tắc phải tuân thủ)

- [Shared Workflow](../../rules/shared-workflow.md)
- [Shared Architecture Rules](../../rules/shared-architecture-rules.md)
- [Shared Reporting Rules](../../rules/shared-reporting-rules.md)
- Tham chiếu kỹ thuật khi viết Live HTTP Integration Test Backend: [smp-newTesting](../smp-newTesting/SKILL.md)

---

## 1. Bản đồ Project, Vị trí Test & Framework

| Project | Tên chuẩn trong tài liệu | Thư mục test | Quy ước tên file | Framework & Thư viện chính | Lệnh chạy test |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Flutter Client (Native)** | `Flutter Client` | `smartspace_client/test/` | `*_test.dart` | `flutter_test`, `flutter_riverpod`, `shared_preferences`, `test/helpers/firebase_test_mock.dart` | `npm run client:test:native` hoặc `npm run test:smp -- SMP-XXX` |
| **Flutter Admin (Native)** | `Flutter Admin` | `smartspace_admin/test/` | `*_test.dart` | `flutter_test`, `flutter_riverpod`, `fl_chart`, `test/helpers/firebase_test_mock.dart` | `npm run admin:test:native` hoặc `npm run test:smp -- SMP-XXX` |
| **Flutter Staff (Native)** | `Flutter Staff` | `smartspace_staff/test/` | `*_test.dart` | `flutter_test`, `flutter_riverpod`, `test/helpers/firebase_test_mock.dart` | `npm run staff:test:native` hoặc `npm run test:smp -- SMP-XXX` |
| **Flutter Shared (Native)** | `Flutter Shared (mobile_shared)` | `mobile_shared/test/` | `*_test.dart` | `flutter_test` | `npm run shared:test:native` hoặc `npm run test:smp -- SMP-XXX` |
| **Spring Boot Backend (Native)** | `Spring Boot Backend` | `SmartSpace_Backend/src/test/java/com/vn/smart_space/` | `*Test.java` / `*Tests.java` | JUnit 5 (`org.junit.jupiter.api.*`), Mockito (`@ExtendWith(MockitoExtension.class)`), `java.net.http.HttpClient` + `Nimbus JWT`, `@SpringBootTest` (nếu cần) | Unit: `npm run backend:test:native`<br>Controller Live HTTP: `npm run backend:test:integration` / `.\testapi.ps1 <CommandName>`<br>Đơn lẻ: `npm run test:smp -- SMP-XXX` |
| **Playwright Backend (API)** | `Spring Boot Backend` | `playwright/backend/` | `*.spec.ts` | `@playwright/test`, TypeScript, `playwright/fixtures/api.fixture.ts` | `npm run backend:test` hoặc `-- --grep "SMP-XXX"` |
| **Playwright Admin (Web UI/E2E)** | `Flutter Admin` | `playwright/admin/` | `*.spec.ts` | `@playwright/test`, TypeScript, `playwright/fixtures/flutter-web.fixture.ts` | `npm run admin:test` hoặc `-- --grep "SMP-XXX"` |
| **Playwright Staff (Web UI/E2E)** | `Flutter Staff` | `playwright/staff/` | `*.spec.ts` | `@playwright/test`, TypeScript, `playwright/fixtures/flutter-web.fixture.ts` | `npm run staff:test` hoặc `-- --grep "SMP-XXX"` |
| **Playwright Client (Web UI/E2E)** | `Flutter Client` | `playwright/client/` | `*.spec.ts` | `@playwright/test`, TypeScript, `playwright/fixtures/flutter-web.fixture.ts` | `npm run client:test` hoặc `-- --grep "SMP-XXX"` |

---

## 2. Quy trình thực hiện (Workflow 7 bước)

### Bước 1 — Phân tích yêu cầu, Chọn tầng kiểm thử & Kiểm tra mã nguồn thực tế
1. Tiếp nhận yêu cầu kiểm thử (một hoặc nhiều kịch bản).
2. Xác định rõ cho từng test case dự kiến:
   - **Chức năng / Nghiệp vụ** được kiểm thử.
   - **Project tương ứng** (`Flutter Client`, `Flutter Admin`, `Flutter Staff`, `Spring Boot Backend`, hoặc `Flutter Shared (mobile_shared)`).
   - **Phạm vi & Engine thực thi:**
     - Chọn **Playwright** (`playwright/<region>/*.spec.ts`) cho kiểm thử API Automation (HTTP status, payload, RBAC, Auth) hoặc Web UI / E2E trên Flutter Web (điều hướng GoRouter, form validation, đăng nhập kết nối Backend thật, hiển thị responsive).
     - Chọn **Native** (`*_test.dart` hoặc `*Test.java`) cho Unit Test, Widget Test dùng provider/repo fake, `@SpringBootTest`, Live HTTP Controller Test (`HttpClient` + `Nimbus JWT`), hoặc luồng phụ thuộc SDK native-only (Mapbox SDK mobile, camera/gallery, FCM native).
     - Nếu một tính năng mới vừa cần Unit/Widget test native vừa cần kiểm thử E2E/API qua Playwright, tạo **hai nhóm mã `SMP-XXX` riêng biệt** tương ứng hai tầng này (tuyệt đối không gộp chung một mã).
   - **Luồng xử lý, điều kiện đầu vào (Input), kết quả mong đợi (Expected Output) và ngoại lệ / biên**.
3. **Đọc mã nguồn thực tế** của màn hình, provider, service, controller, DTO hoặc model liên quan để xác định chính xác hành vi thật và vị trí đặt file test theo convention hiện tại.
4. **Dừng lại hỏi người dùng (STOP CONDITION)** nếu thông tin đầu vào chưa đủ cơ sở để xác định nghiệp vụ, input hoặc kết quả kỳ vọng chính xác. **TUYỆT ĐỐI KHÔNG** tự suy đoán nghiệp vụ hoặc tự bịa dữ liệu giả để lấp chỗ trống.

---

### Bước 2 — Xác định & Cấp mã số `SMP-XXX`
Mỗi test case độc lập phải có một mã số duy nhất theo định dạng:

`SMP-XXX`

Trong đó:
- `SMP` là tiền tố cố định.
- `XXX` là số thứ tự gồm tối thiểu 3 chữ số (zero-padded, bắt đầu từ `001`: `SMP-001`, `SMP-002`, ..., `SMP-999`, `SMP-1000` nếu vượt 999).
- Mỗi mã chỉ dùng cho **một test case duy nhất**; không tái sử dụng mã đã từng tồn tại hoặc đã bị gán.

**Quy trình tìm mã tiếp theo:**
1. Kiểm tra mã `SMP-XXX` lớn nhất hiện có trong:
   - `docs/TestCaseList.md`
   - Danh sách file trong `docs/TestCases/`
   - Các chú thích `Test Case ID: SMP-` trong toàn bộ file test native (`*_test.dart`, `*Test*.java`) **và** các file Playwright (`playwright/**/*.spec.ts`).
2. Lấy $M = \max(\text{tất cả mã hiện có})$ (nếu chưa có mã nào thì $M = 0$).
3. Khi tạo $N$ test case mới trong cùng một lần thực hiện, cấp tuần tự từ `SMP-(M+1)` đến `SMP-(M+N)` (không bao giờ cấp trùng mã).

---

### Bước 3 — Triển khai file test thực tế & Gắn mã trong code
Triển khai test vào đúng project và đúng cấu trúc thư mục hiện hành:

1. **Yêu cầu chất lượng code test:**
   - Dùng đúng framework và thư viện test của project (không tự ý cài thêm thư viện nếu chưa cần thiết và chưa được cho phép).
   - Test phải có khả năng **thực thi thực tế**, có assertion rõ ràng, không tạo file chỉ chứa mô tả hoặc placeholder.
   - Không tạo mock hoặc dữ liệu giả tùy tiện; chỉ dùng fake/mock (`Mockito`, `_Fake*Repo`, `ProviderScope overrides`, v.v.) khi phù hợp với phạm vi unit/widget test và không làm sai lệch nghiệp vụ.
   - **Test-only Firebase Mock (khi test Widget cần khởi tạo `SmartSpace*App` / `FirebaseService`):** Sử dụng `setupFirebaseTestMocks()` từ `test/helpers/firebase_test_mock.dart` của app tương ứng và dọn bằng `tearDownFirebaseTestMocks()`. **TUYỆT ĐỐI KHÔNG** import hoặc để test mock Firebase ảnh hưởng đến bất kỳ file nào trong `lib/`.
   - Với **Playwright (`playwright/<region>/*.spec.ts`)**: Tái sử dụng `loginViaApi` / `logoutViaApi` (`playwright/fixtures/api.fixture.ts`), `bootFlutterWeb` / `fillFlutterInput` / `getSemanticText` (`playwright/fixtures/flutter-web.fixture.ts`) và `PW_ENV` (`playwright/config/env.ts`). Không hardcode mật khẩu hoặc URL cổng cố định vào spec.
   - **TUYỆT ĐỐI KHÔNG** sửa đổi logic production chỉ để ép test pass.
   - **TUYỆT ĐỐI KHÔNG** làm hỏng hoặc thay đổi hành vi các test case hiện có.
   - Nếu viết Live HTTP Integration Test cho Backend, tuân thủ thêm các bước của `smp-newTesting` (health check port `8989`, không dùng `@SpringBootTest`, đăng ký vào `testapi.ps1` nếu phù hợp).

2. **Quy tắc gắn chú thích mã số trong file test (BẮT BUỘC):**
   Đặt comment trực tiếp ngay phía trên từng test case độc lập (giữ nguyên thụt lề của block test):

   - **Trong Dart (`*_test.dart`):**
     ```dart
     // Test Case ID: SMP-001
     // Description: Mô tả ngắn gọn nội dung kiểm thử.
     test('...', () async {
       ...
     });
     ```
   - **Trong Java (`*Test.java` / `*Tests.java`):**
     ```java
     // Test Case ID: SMP-164
     // Description: Mô tả ngắn gọn nội dung kiểm thử.
     @Test
     @DisplayName("...")
     void shouldDoSomething() {
         ...
     }
     ```
   - **Trong Playwright TypeScript (`*.spec.ts`):**
     ```ts
     // Test Case ID: SMP-336
     // Description: Mô tả ngắn gọn nội dung kiểm thử.
     test('[SMP-336] Mô tả ngắn gọn test case', async ({ request }) => {
       ...
     });
     ```
     *(Bắt buộc đưa `[SMP-XXX]` vào tên `test(...)` để hỗ trợ lọc `-- --grep "SMP-XXX"`.)*
   - **Quy tắc gom/tách mã số:**
     - Mỗi test case độc lập (`test`, `testWidgets`, `@Test`) có **1 mã `SMP-XXX` riêng**.
     - Nếu một file có nhiều test case độc lập, **PHẢI** cấp và gắn mã riêng cho từng test case; không gán một mã chung cho nhiều test case độc lập.
     - Nếu một `@ParameterizedTest` (Java) hoặc một vòng lặp `for` trong Dart kiểm thử **cùng một tình huống logic** qua nhiều biến thể tham số (ví dụ Light/Dark theme hoặc danh sách role), gắn **1 mã `SMP-XXX`** ngay phía trên annotation/vòng lặp đó và mô tả đầy đủ các biến thể trong file tài liệu.
     - Nếu nhiều assertion thuộc cùng một tình huống kiểm thử trong một test method/block, giữ nguyên là **1 test case**.

---

### Bước 4 — Tạo tài liệu chi tiết `docs/TestCases/SMP-XXX.md`
Mỗi test case bắt buộc có một file Markdown riêng tại `docs/TestCases/SMP-XXX.md` (tên file trùng khít mã số). Nếu tạo nhiều test case, phải tạo đủ $N$ file chi tiết tương ứng.

**Template chuẩn bắt buộc (đủ 13 mục):**

```markdown
# SMP-XXX: <Tên test case ngắn gọn, chính xác>

1. **Mã số test case:** SMP-XXX
2. **Tên test case:** <Tên ngắn gọn, thể hiện chính xác nội dung kiểm thử>
3. **Project:** <Flutter Client | Flutter Admin | Flutter Staff | Spring Boot Backend | Flutter Shared (mobile_shared)>
4. **Chức năng:** <Tên chức năng / nghiệp vụ được kiểm thử>
5. **Loại kiểm thử:** <Unit Test | Widget Test | Integration Test | API Integration Test (Live HTTP) | ...>
6. **Mô tả test case:** <Mô tả chi tiết tình huống kiểm thử dựa trên code thực tế>
7. **Mục đích kiểm thử:** <Lý do cần thực hiện và điều cần xác minh của test case này>
8. **Điều kiện tiên quyết:** <Môi trường, trạng thái dữ liệu, mock/fake, hoặc điều kiện cần thiết trước khi chạy>
9. **Các bước kiểm thử:**

| Bước | Thao tác | Input | Kết quả kỳ vọng |
|---|---|---|---|
| 1 | ... | ... | ... |
| 2 | ... | ... | ... |

10. **Input từng bước:** <Tóm tắt hoặc đối chiếu input tương ứng các bước 1..k trong bảng ở mục 9>
11. **Kỳ vọng từng bước:** <Tóm tắt hoặc đối chiếu kết quả kỳ vọng tương ứng các bước 1..k trong bảng ở mục 9>
12. **File test tương ứng:** `<đường dẫn tương đối từ root workspace>`
13. **Ghi chú:** <Thông tin bổ sung; nếu có nội dung chưa đủ cơ sở xác minh từ mã nguồn, tách bạch rõ phần đã xác minh và phần chưa đủ cơ sở>
```

> **Lưu ý chất lượng tài liệu:** Nội dung phải đủ rõ để người đọc hiểu được test case mà không cần mở file mã nguồn; mọi con số, trạng thái, thông điệp lỗi, field JSON và assertion phải khớp 100% với code thực tế (không bịa đặt).

---

### Bước 5 — Cập nhật danh sách tổng hợp `docs/TestCaseList.md`
- Nếu `docs/TestCaseList.md` chưa tồn tại: tạo mới file.
- Nếu `docs/TestCaseList.md` đã tồn tại: **cập nhật bổ sung/chỉnh sửa đúng dòng liên quan**, tuyệt đối không ghi đè làm mất các test case cũ.
- Bắt buộc chứa bảng 9 cột chuẩn sau:

```markdown
| STT | Mã test case | Tên test case | Project | Chức năng | Mô tả Input | Kỳ vọng đầu ra | Mục đích kiểm thử | Chi tiết |
|---|---|---|---|---|---|---|---|---|
| 1 | SMP-001 | ... | Flutter Client | ... | ... | ... | ... | [Xem chi tiết](TestCases/SMP-001.md) |
```

**Quy định bảng tổng hợp:**
- Mỗi test case tương ứng đúng 1 dòng.
- `STT` đánh tuần tự `1, 2, 3, ...`
- Sắp xếp tăng dần theo `Mã test case` (`SMP-001`, `SMP-002`, ...).
- `Mã test case` là duy nhất.
- `Mô tả Input`: tóm tắt dữ liệu đầu vào quan trọng.
- `Kỳ vọng đầu ra`: mô tả kết quả tổng thể mong đợi.
- `Mục đích kiểm thử`: nêu rõ nội dung cần xác minh.
- `Chi tiết`: bắt buộc dùng link Markdown `[Xem chi tiết](TestCases/SMP-XXX.md)`.
- Nếu nội dung trong ô bảng có ký tự `|`, phải escape thành `\|` (và dùng `<br>` thay xuống dòng) để không vỡ bảng Markdown.

---

### Bước 6 — Đăng ký & Tích hợp vào Hệ thống Automation (Playwright + CI)
Đảm bảo mọi test case vừa tạo (dù là Playwright hay Native) đều được hệ thống Automation Testing phát hiện và chạy kèm toàn bộ test case cũ trong lần chạy tiếp theo (local và GitHub Actions):

1. **Kiểm tra vị trí & quy ước tự động phát hiện (Auto-discovery):**
   - **Playwright (`playwright/<region>/*.spec.ts`):** Đặt file trong đúng vùng (`backend`, `admin`, `staff`, `client`) với hậu tố `.spec.ts` và `[SMP-XXX]` trong tiêu đề `test(...)` để `playwright.config.ts`, `npm run test:all`, `npm run <region>:test` và `.github/workflows/playwright-automation.yml` tự động chạy cùng các spec cũ.
   - **Flutter Native (`smartspace_client/test/`, `smartspace_admin/test/`, `smartspace_staff/test/`, `mobile_shared/test/`):** Đặt file với hậu tố `_test.dart` để `npm run <app>:test:native` và GitHub Actions tự động thực thi cùng toàn bộ test cũ.
   - **Spring Boot Backend Native:**
     - Offline Unit Test dưới `configuration/**` hoặc `service/**` kết thúc bằng `*Test.java`: tự động được gom vào `npm run backend:test:native` (lệnh dùng glob loại trừ `controller.**` và `SmartSpaceApplicationTests`).
     - Live HTTP Controller Test dưới `controller/**` kết thúc bằng `*Test.java`: tự động được gom vào `npm run backend:test:integration` và CI; đồng thời đăng ký thêm vào `testapi.ps1` theo `smp-newTesting`.
   - Nếu tạo test ở thư mục mới hoặc định dạng tên khác ngoài quy ước trên, **BẮT BUỘC** cập nhật tương ứng [playwright.config.ts](../../../playwright.config.ts), [package.json](../../../package.json) hoặc [.github/workflows/playwright-automation.yml](../../../.github/workflows/playwright-automation.yml) để không bị bỏ sót test khi chạy automation tổng thể.

2. **Bổ sung Playwright Automation khi tạo test cho tính năng Web/API mới:**
   - Khi tính năng mới có API endpoint mới hoặc luồng màn hình Flutter Web mới, nếu người dùng yêu cầu kiểm thử tính năng hoặc mở rộng E2E/API, **PHẢI** tạo test Playwright trong `playwright/<region>/*.spec.ts` (với mã `SMP-XXX` riêng biệt, tài liệu `docs/TestCases/SMP-XXX.md` và dòng trong `docs/TestCaseList.md`) để `npm run test:all` và CI bao phủ luôn tính năng đó ở lần chạy kế tiếp.

---

### Bước 7 — Kiểm tra tính đồng bộ & Thực thi kiểm thử (Cũ + Mới)
Trước khi kết thúc, bắt buộc thực hiện đầy đủ 2 nhóm kiểm tra:

1. **Kiểm tra tính đồng bộ 10 điểm:**
   - [ ] File test thực tế tồn tại đúng vị trí theo convention của project.
   - [ ] Trong file test có comment `// Test Case ID: SMP-XXX` ngay phía trên đúng test case tương ứng (và `[SMP-XXX]` trong tiêu đề nếu là Playwright).
   - [ ] File `docs/TestCases/SMP-XXX.md` tồn tại đầy đủ cho mọi mã mới (cột 12 `File test tương ứng` đúng đường dẫn tương đối).
   - [ ] `docs/TestCaseList.md` có đầy đủ dòng tương ứng và sắp xếp tăng dần theo `SMP-XXX`, STT liên tục.
   - [ ] Link `[Xem chi tiết](TestCases/SMP-XXX.md)` khớp đúng tên file tồn tại trong `docs/TestCases/`.
   - [ ] `node -e "const r=require('./playwright/helpers/smp-registry.mjs'); const reg=r.loadSmpRegistry(); console.log(reg.size);"` nhận diện đủ 100% test case (không bỏ sót dòng do escape `\|` hay lỗi format).
   - [ ] Không có mã `SMP-XXX` bị trùng lặp trong code test, `docs/TestCases/` hay `docs/TestCaseList.md`.
   - [ ] Không có test case được ghi trong tài liệu mà thiếu code test thực tế (trừ khi user yêu cầu rõ chỉ lập tài liệu thiết kế test).
   - [ ] Không sửa `lib/` hay làm hỏng test hiện có khi dùng mock Firebase/test helpers.
   - [ ] Test case mới nằm trong phạm vi tự động chạy của `npm run <region>:test` / `npm run <region>:test:native` / `npm run test:all` và CI workflow.

2. **Chạy kiểm thử thực tế (xác nhận cả cũ lẫn mới):**
   - Chạy đơn lẻ test vừa tạo: `npm run test:smp -- SMP-XXX` (hoặc `npm run <region>:test -- --grep "SMP-XXX"` nếu là Playwright) — **PHẢI xác nhận số test thực thi >= 1** (không chấp nhận `Tests run: 0` hoặc `No tests found`).
   - Chạy bộ kiểm thử đầy đủ của vùng tương ứng (`npm run <region>:test`, `npm run <region>:test:native`, hoặc `npm run test:all`) để đảm bảo cả test cũ lẫn test mới đều thực thi đầy đủ và PASS.
   - Báo cáo trung thực trạng thái từng test: `PASS`, `FAIL`, `SKIPPED`, hoặc `BLOCKED` kèm lý do. **KHÔNG** báo PASS nếu chưa chạy.

---

## 3. Quy định bắt buộc cho mọi lần sử dụng & Nguyên tắc an toàn

1. **Tính toàn vẹn chuỗi thực hiện:** Không bao giờ tạo code test mới mà quên tạo `docs/TestCases/SMP-XXX.md`, cập nhật `docs/TestCaseList.md` và xác nhận tích hợp Playwright/CI.
2. **Không tạo tài liệu suông:** Không tạo file `SMP-XXX.md` hay thêm dòng vào `TestCaseList.md` khi chưa có test thực tế, trừ khi người dùng yêu cầu tường minh chỉ lập tài liệu thiết kế test.
3. **Không phá hoại dữ liệu cũ:** Không xóa, không ghi đè mất các test case cũ đã tồn tại trong code, `docs/TestCases/` hoặc `docs/TestCaseList.md`.
4. **Không suy diễn khi thiếu thông tin:** Nếu phát hiện thiếu dữ liệu hoặc test cũ thiếu assertion / thông tin mơ hồ, ghi nhận rõ ràng và phân tách phần đã xác minh với phần chưa đủ cơ sở.
5. **Bảo toàn production & cấu hình:** Không sửa logic production để ép test pass; không để test mock Firebase rò vào `lib/`; không hardcode secret/mật khẩu thật; không tự commit hoặc push Git.
