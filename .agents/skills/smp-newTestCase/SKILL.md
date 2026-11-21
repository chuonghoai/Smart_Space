---
name: smp-newTestCase
description: >-
  Tạo một hoặc nhiều test case thực thi được cho 4 project (Flutter Client, Flutter Admin, Flutter Staff, Spring Boot Backend) và mobile_shared, tự động cấp mã SMP-XXX duy nhất, gắn chú thích mã trong file test, tạo tài liệu chi tiết tại docs/TestCases/SMP-XXX.md và đồng bộ docs/TestCaseList.md.
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
| **Flutter Client** | `Flutter Client` | `smartspace_client/test/` | `*_test.dart` | `flutter_test`, `flutter_riverpod`, `shared_preferences` | `cd smartspace_client && flutter test` |
| **Flutter Admin** | `Flutter Admin` | `smartspace_admin/test/` | `*_test.dart` | `flutter_test`, `flutter_riverpod`, `fl_chart` | `cd smartspace_admin && flutter test` |
| **Flutter Staff** | `Flutter Staff` | `smartspace_staff/test/` | `*_test.dart` | `flutter_test`, `flutter_riverpod` | `cd smartspace_staff && flutter test` |
| **Flutter Shared** | `Flutter Shared (mobile_shared)` | `mobile_shared/test/` | `*_test.dart` | `flutter_test` | `cd mobile_shared && flutter test` |
| **Spring Boot Backend** | `Spring Boot Backend` | `SmartSpace_Backend/src/test/java/com/vn/smart_space/` | `*Test.java` / `*Tests.java` | JUnit 5 (`org.junit.jupiter.api.*`), Mockito (`@ExtendWith(MockitoExtension.class)`), `java.net.http.HttpClient` + `Nimbus JWT`, `@SpringBootTest` (nếu cần) | Unit/Compile: `cd SmartSpace_Backend && mvn test "-Dtest=<Class>" "-Dfile.encoding=UTF-8"`<br>Live HTTP: `.\testapi.ps1 <CommandName>` (cần backend chạy ở `:8989`) |

---

## 2. Quy trình thực hiện (Workflow 6 bước)

### Bước 1 — Phân tích yêu cầu & Kiểm tra mã nguồn thực tế
1. Tiếp nhận yêu cầu kiểm thử (một hoặc nhiều kịch bản).
2. Xác định rõ cho từng test case dự kiến:
   - **Chức năng / Nghiệp vụ** được kiểm thử.
   - **Project tương ứng** (`Flutter Client`, `Flutter Admin`, `Flutter Staff`, `Spring Boot Backend`, hoặc `Flutter Shared (mobile_shared)`).
   - **Phạm vi & Loại kiểm thử**: `Unit Test`, `Widget Test`, `Integration Test`, `API Integration Test (Live HTTP)`, v.v.
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
   - Các chú thích `Test Case ID: SMP-` trong toàn bộ file test của cả 4 project và `mobile_shared`.
2. Lấy $M = \max(\text{tất cả mã hiện có})$ (nếu chưa có mã nào thì $M = 0$).
3. Khi tạo $N$ test case mới trong cùng một lần thực hiện, cấp tuần tự từ `SMP-(M+1)` đến `SMP-(M+N)` (không bao giờ cấp trùng mã).

---

### Bước 3 — Triển khai file test thực tế & Gắn mã trong code
Triển khai test vào đúng project và đúng cấu trúc thư mục hiện hành:

1. **Yêu cầu chất lượng code test:**
   - Dùng đúng framework và thư viện test của project (không tự ý cài thêm thư viện nếu chưa cần thiết và chưa được cho phép).
   - Test phải có khả năng **thực thi thực tế**, có assertion rõ ràng, không tạo file chỉ chứa mô tả hoặc placeholder.
   - Không tạo mock hoặc dữ liệu giả tùy tiện; chỉ dùng fake/mock (`Mockito`, `_Fake*Repo`, `ProviderScope overrides`, v.v.) khi phù hợp với phạm vi unit/widget test và không làm sai lệch nghiệp vụ.
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

### Bước 6 — Kiểm tra tính đồng bộ & Thực thi kiểm thử
Trước khi kết thúc, bắt buộc thực hiện đầy đủ 2 nhóm kiểm tra:

1. **Kiểm tra tính đồng bộ 8 điểm:**
   - [ ] File test thực tế tồn tại đúng vị trí theo convention của project.
   - [ ] Trong file test có comment `// Test Case ID: SMP-XXX` ngay phía trên đúng test case tương ứng.
   - [ ] File `docs/TestCases/SMP-XXX.md` tồn tại đầy đủ cho mọi mã mới.
   - [ ] `docs/TestCaseList.md` có đầy đủ dòng tương ứng và sắp xếp tăng dần theo `SMP-XXX`, STT liên tục.
   - [ ] Link `[Xem chi tiết](TestCases/SMP-XXX.md)` khớp đúng tên file tồn tại trong `docs/TestCases/`.
   - [ ] Không có mã `SMP-XXX` bị trùng lặp trong code test, `docs/TestCases/` hay `docs/TestCaseList.md`.
   - [ ] Không có test case được ghi trong tài liệu mà thiếu code test thực tế (trừ khi user yêu cầu rõ chỉ lập tài liệu thiết kế test).
   - [ ] Không có test case mới nào trong file test bị thiếu trong `docs/TestCaseList.md` hoặc `docs/TestCases/`.

2. **Chạy kiểm thử thực tế (nếu môi trường cho phép):**
   - Chạy lệnh test phù hợp của project bị tác động (hoặc file test vừa tạo).
   - Báo cáo trung thực trạng thái từng test: `PASS`, `FAIL`, `SKIPPED`, hoặc `BLOCKED` kèm lý do (ví dụ: backend port `8989` chưa bật). **KHÔNG** báo PASS nếu chưa chạy.

---

## 3. Quy định bắt buộc cho mọi lần sử dụng & Nguyên tắc an toàn

1. **Tính toàn vẹn chuỗi thực hiện:** Không bao giờ tạo code test mới mà quên tạo `docs/TestCases/SMP-XXX.md` và cập nhật `docs/TestCaseList.md`.
2. **Không tạo tài liệu suông:** Không tạo file `SMP-XXX.md` hay thêm dòng vào `TestCaseList.md` khi chưa có test thực tế, trừ khi người dùng yêu cầu tường minh chỉ lập tài liệu thiết kế test.
3. **Không phá hoại dữ liệu cũ:** Không xóa, không ghi đè mất các test case cũ đã tồn tại trong code, `docs/TestCases/` hoặc `docs/TestCaseList.md`.
4. **Không suy diễn khi thiếu thông tin:** Nếu phát hiện thiếu dữ liệu hoặc test cũ thiếu assertion / thông tin mơ hồ, ghi nhận rõ ràng và phân tách phần đã xác minh với phần chưa đủ cơ sở.
5. **Bảo toàn production & cấu hình:** Không sửa logic production để ép test pass; không tự ý cài thêm thư viện, đổi cấu hình build/môi trường; không tự commit hoặc push Git.
