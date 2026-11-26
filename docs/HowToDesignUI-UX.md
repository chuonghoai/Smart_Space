# Hướng dẫn Thiết kế & Tinh chỉnh UI/UX với `design-taste-frontend` và `impeccable`

Tài liệu này hướng dẫn cách kết hợp và khai thác tối đa sức mạnh của 2 AI Skill thiết kế giao diện trong dự án **SmartSpace**:
1. **`impeccable`**: Từ điển lệnh thiết kế và quy trình tinh chỉnh UI/UX cấp chuyên gia (Craft, Polish, Audit, Harden...).
2. **`design-taste-frontend` (`taste-skill` v2)**: Định hướng mỹ thuật (Art Direction), layout cao cấp, và kỷ luật chống giao diện rập khuôn AI (Anti-slop Discipline).

Toàn bộ quy chuẩn về màu sắc (Teal `#00796B` + Green `#558B2F`), typography, spacing, Dark/Light Mode và quy tắc đa ngôn ngữ (L10n) được quy định thống nhất tại [`DESIGN.md`](../DESIGN.md) và [`PRODUCT.md`](../PRODUCT.md) ở thư mục gốc.

---

## MỤC LỤC
1. [Cách sử dụng Impeccable & Bảng tra cứu Commands](#1-cách-sử-dụng-impeccable--bảng-tra-cứu-commands)
2. [Cách sử dụng Design-Taste-Frontend](#2-cách-sử-dụng-design-taste-frontend)
3. [Quy trình Phối hợp Đồng thời Cả 2 Skill (The Master Workflow)](#3-quy-trình-phối-hợp-đồng-thời-cả-2-skill-the-master-workflow)
4. [Các Kịch bản Thực tế: Thêm Mới & Chỉnh sửa UI/UX](#4-các-kịch-bản-thực-tế-thêm-mới--chỉnh-sửa-uiux)
   - [Kịch bản 1: Tạo mới màn hình "Báo cáo sự cố" (Client App)](#kịch-bản-1-tạo-mới-màn-hình-báo-cáo-sự-cố-client-app)
   - [Kịch bản 2: Tinh chỉnh & Làm gọn màn hình Dashboard (Admin Web)](#kịch-bản-2-tinh-chỉnh--làm-gọn-màn-hình-dashboard-admin-web)
   - [Kịch bản 3: Sửa lỗi hiển thị, Tràn chữ & Edge Cases (Staff App)](#kịch-bản-3-sửa-lỗi-hiển-thị-tràn-chữ--edge-cases-staff-app)
5. [Tóm tắt Những Điều Cần Nhớ (Best Practices)](#5-tóm-tắt-những-điều-cần-nhớ-best-practices)

---

## 1. Cách sử dụng Impeccable & Bảng tra cứu Commands

### 1.1. Nguyên lý hoạt động
- **Kích hoạt qua Chat:** Mọi lệnh của Impeccable được gọi trực tiếp bằng cách chat với AI Assistant (ví dụ: gõ `/impeccable <command> [target]` hoặc yêu cầu bằng lời nói tự nhiên trong khung chat).
- **Ngữ cảnh tự động:** Impeccable tự động đọc [`PRODUCT.md`](../PRODUCT.md) (hiểu nghiệp vụ đô thị thông minh) và [`DESIGN.md`](../DESIGN.md) (hiểu token, màu sắc, font chữ).
- **Hỗ trợ Native Platform:** Tự động kích hoạt bộ luật Android Material 3 và iOS HIG khi làm việc trên Flutter.

### 1.2. Bảng 24 Commands của Impeccable

| Nhóm | Lệnh (Command) | Ý nghĩa & Khi nào nên dùng | Ví dụ câu lệnh trong Chat |
| :--- | :--- | :--- | :--- |
| **Plan & Build** | `shape [feature]` | Lên kế hoạch cấu trúc UX/UI, luồng tương tác trước khi code. | `/impeccable shape luồng tạo phản ánh khẩn cấp` |
| | `document` | Quét mã nguồn và tổng hợp/cập nhật `DESIGN.md`. | `/impeccable document` |
| | `extract [target]` | Tách các pattern, style hoặc widget lặp lại thành component tái sử dụng. | `/impeccable extract card sự cố trong client app` |
| **Evaluate** | `critique [target]` | Đánh giá thiết kế theo thang điểm Heuristic (tính dễ dùng, độ rõ ràng, thứ bậc). | `/impeccable critique màn hình bản đồ sự cố` |
| | `audit [target]` | Kiểm tra chất lượng kỹ thuật sâu: A11y (độ tương phản, touch target 48dp), Dark/Light mode, Responsive. | `/impeccable audit smartspace_client/lib/features/report` |
| **Refine** | `polish [target]` | **Bước hoàn thiện cuối cùng trước khi merge/commit**: Căn chỉnh khoảng cách, padding, font, icon, màu sắc đạt chuẩn hoàn hảo. | `/impeccable polish màn hình chi tiết sự cố` |
| | `bolder [target]` | Tăng cá tính, làm nổi bật các phần tử quá phẳng lì, mờ nhạt hoặc đơn điệu. | `/impeccable bolder nút bấm và card thống kê admin` |
| | `quieter [target]` | Hạ nhiệt thị giác cho màn hình quá rối mắt, quá nhiều màu gắt hoặc quá nhiều card lồng nhau. | `/impeccable quieter bảng điều khiển trung tâm admin` |
| | `distill [target]` | Lược bỏ các thành phần rườm rà, giữ lại tinh hoa chức năng để người dùng tập trung làm việc. | `/impeccable distill form nhập thông tin sự cố` |
| | `harden [target]` | **Làm vững chắc cho Production**: Xử lý triệt để loading state, empty state, error state, lỗi tràn text (overflow), đa ngôn ngữ (L10n). | `/impeccable harden danh sách phản ánh của tôi` |
| | `onboard [target]` | Thiết kế trải nghiệm lần đầu mở app, các màn hình hướng dẫn và empty state kích hoạt hành động. | `/impeccable onboard trang chủ client khi chưa có báo cáo` |
| **Enhance** | `typeset [target]` | Tinh chỉnh phân cấp chữ: font scale, line-height, font-weight (Regular/Medium/Bold). | `/impeccable typeset tiêu đề và nội dung thẻ sự cố` |
| | `colorize [target]` | Bổ sung màu sắc thương hiệu/ngữ nghĩa một cách có chiến lược vào UI bị xám xịt. | `/impeccable colorize chip phân loại sự cố môi trường` |
| | `layout [target]` | Điều chỉnh nhịp điệu (rhythm), margin, padding theo hệ base 4px chuẩn. | `/impeccable layout danh sách phân công cho staff` |
| | `animate [target]` | Bổ sung hoạt ảnh vi mô tinh tế (100–250ms), container transform, hiệu ứng chuyển tab. | `/impeccable animate chuyển đổi giữa bản đồ và danh sách` |
| | `delight [target]` | Thêm các chi tiết nhỏ tinh tế tạo thiện cảm (micro-delights, rung phản hồi, hình vẽ nhẹ nhàng). | `/impeccable delight trạng thái gửi phản ánh thành công` |
| | `overdrive [target]` | Đẩy cao giới hạn đồ họa (hiệu ứng shader, visual effect nâng cao). | `/impeccable overdrive visual radar quét vị trí sự cố` |
| **Fix** | `clarify [target]` | Viết lại câu chữ UX copy, nhãn nút, thông báo lỗi cho người dùng dễ hiểu. | `/impeccable clarify các thông báo lỗi xác thực form` |
| | `adapt [target]` | Điều chỉnh giao diện thích ứng đa màn hình (Điện thoại, Tablet, Desktop Web). | `/impeccable adapt màn hình quản lý phòng lên desktop web` |
| | `optimize [target]` | Chẩn đoán và khắc phục giật lag UI, hạn chế rebuild widget không cần thiết. | `/impeccable optimize list view hiển thị 100 điểm sự cố` |
| **Iterate** | `live` / `generate` | Chế độ sinh và thử nghiệm nhanh các biến thể giao diện khác nhau. | `/impeccable generate 3 variants cho nút trạng thái` |

---

## 2. Cách sử dụng Design-Taste-Frontend

### 2.1. Mục đích cốt lõi
`design-taste-frontend` có nhiệm vụ đảm bảo giao diện SmartSpace không rơi vào bẫy **AI-Slop** (giao diện rập khuôn, vô hồn do AI tự tạo: gradient tím xanh, bo góc vô tội vạ, thẻ lồng thẻ, icon đặt trong hộp tròn mờ mờ).

### 2.2. Ba bước kỷ luật bắt buộc của Taste-Skill

#### 1️⃣ Bước 1: Brief Inference & Xuất dòng "Design Read"
Trước khi viết bất kỳ dòng code UI nào, Agent bắt buộc phải suy luận và xuất ra một dòng xác nhận duy nhất:
> **"Reading this as: `<page kind>` for `<audience>`, with a `<vibe>` language, leaning toward `<design system or aesthetic family>`."**

*Ví dụ trong SmartSpace:*
- Cho Client App: *"Reading this as: mobile civic reporting screen for citizens on the move, with a trust-first calm language, leaning toward Flutter Material 3 + Teal/Green tokens."*
- Cho Admin App: *"Reading this as: high-density operations dashboard for municipal dispatchers, with a data-first scannable language, leaning toward multi-column desktop layout."*

#### 2️⃣ Bước 2: Thiết lập The Three Dials (Bộ ba thông số)
Tùy vào loại màn hình, ta cấu hình mức độ từ 0 đến 10:
1. `DESIGN_VARIANCE` (0–10): Mức độ phá cách thị giác (0: bám sát chuẩn; 10: thể nghiệm nghệ thuật).
   - Với SmartSpace App (Operate/Task): Đặt **1–3** (tập trung tính dễ dùng, quen thuộc).
   - Với Landing/Intro: Đặt **6–8**.
2. `MOTION_INTENSITY` (0–10): Mức độ chuyển động hoạt ảnh.
   - Với SmartSpace: Đặt **1–3** (chuyển động tinh tế 150–250ms, không gây xao nhãng khi thao tác hiện trường).
3. `VISUAL_DENSITY` (0–10): Mật độ thông tin trên màn hình.
   - Với Client App: Đặt **4–5** (khoảng thở rộng rãi, dễ bấm ngoài trời).
   - Với Admin Dashboard: Đặt **7–8** (nhiều dữ liệu, bảng biểu, danh sách gọn gàng).

#### 3️⃣ Bước 3: Anti-Default Discipline (Kỷ luật chống rập khuôn)
- **Không dùng đường kẻ mảnh (Hairline dividers) liên tục:** Thay vì kẻ vạch xám ngang dọc chia cắt giao diện, hãy phân tách bằng khoảng trắng (spacing 16px/24px) hoặc màu nền bề mặt khác sắc độ (`#F5F8F7` vs `#FFFFFF`).
- **Không dùng gradient tím-xanh:** Chỉ dùng dải màu Teal `#00796B` sang Primary Light `#26A69A` khi thực sự cần thiết.
- **Không dùng font Monospace:** Trừ khi hiển thị mã định danh kỹ thuật (ID sự cố, tọa độ GPS).
- **Công cụ kiểm tra (Linter):**
  Bạn có thể chạy kiểm tra vi phạm AI-slop bằng lệnh terminal:
  ```powershell
  node .agents/skills/design-taste-frontend/scripts/lint.mjs
  ```

---

## 3. Quy trình Phối hợp Đồng thời Cả 2 Skill (The Master Workflow)

Khi xây dựng hoặc cải tiến giao diện trong SmartSpace, kết hợp cả 2 skill theo quy trình 4 giai đoạn nhịp nhàng:

```
[ Giai đoạn 1: ĐỊNH HƯỚNG ]
   Taste-Skill: Phân tích người dùng, xuất Design Read, chỉnh Three Dials
   Impeccable: Chạy "shape" định hình cấu trúc thông tin & luồng tương tác
          ↓
[ Giai đoạn 2: THỰC THI (CODE) ]
   Áp dụng Token từ DESIGN.md & app_theme.dart (Teal + Green, Dark/Light)
   Triển khai L10n đầy đủ (AppLocalizations)
   Tuân thủ Anti-Default (phân tách bằng spacing & tone thay vì divider)
          ↓
[ Giai đoạn 3: ĐÁNH GIÁ (AUDIT) ]
   Impeccable: Chạy "audit" (check A11y, Touch Target 48dp, contrast)
   Taste-Skill: Chạy "lint.mjs" (bắt lỗi AI-slop, hairline, font sai)
          ↓
[ Giai đoạn 4: HOÀN THIỆN (POLISH & HARDEN) ]
   Impeccable: Chạy "harden" (phủ kín loading, empty state, error, overflow)
   Impeccable: Chạy "polish" (chốt độ sắc nét pixel trước khi commit)
```

---

## 4. Các Kịch bản Thực tế: Thêm Mới & Chỉnh sửa UI/UX

### Kịch bản 1: Tạo mới màn hình "Báo cáo sự cố" (Client App)

**Mục tiêu:** Xây dựng màn hình cho người dân chụp ảnh hiện trường, chọn vị trí trên bản đồ và gửi báo cáo rác thải/ô nhiễm.

#### Bước 1: Yêu cầu định hướng bằng lệnh Chat
Bạn nhắn cho Agent trong khung Chat:
```text
/impeccable shape Màn hình tạo phản ánh sự cố mới trong smartspace_client. 
Hãy kết hợp với design-taste-frontend để đưa ra Design Read và bộ Three Dials trước khi code.
```

#### Bước 2: Agent phản hồi và thiết lập cấu hình
Agent sẽ phân tích:
- **Design Read:** *"Reading this as: civic reporting flow for citizens on mobile, with an action-oriented, high-trust language, leaning toward Flutter Material 3 + SmartSpace Teal/Green."*
- **Three Dials:** `DESIGN_VARIANCE: 2`, `MOTION_INTENSITY: 2`, `VISUAL_DENSITY: 4`.
- **Luồng 7 bước chuẩn** (từ `DESIGN.md`): Chọn danh mục → Upload ảnh → Nhập mô tả → Chọn vị trí bản đồ → Xem lại → Gửi → Phản hồi thành công.

#### Bước 3: Triển khai Code Flutter
Code được viết tuân thủ:
- Màu nút bấm: Primary `#00796B` (hoặc `#26A69A` ở Dark Mode).
- Vùng chạm tối thiểu: `48x48 dp`.
- Bo góc: `8px` cho nút/input, `12px` cho card chọn ảnh.
- Text: 100% sử dụng `context.l10n.xxx` (không hardcode tiếng Việt/Anh).

#### Bước 4: Kiểm thử và Hoàn thiện
Bạn yêu cầu Agent:
```text
/impeccable audit smartspace_client/lib/features/report/ui/create_report_screen.dart
/impeccable harden màn hình này với các trạng thái: đang tải vị trí GPS, lỗi mất mạng và thông báo thành công.
```

---

### Kịch bản 2: Tinh chỉnh & Làm gọn màn hình Dashboard (Admin Web)

**Mục tiêu:** Màn hình Dashboard Admin hiện đang có quá nhiều thẻ card nhỏ lồng nhau, màu sắc lộn xộn và đường viền chia cắt dày đặc.

#### Bước 1: Yêu cầu đánh giá ban đầu
```text
/impeccable critique Màn hình Dashboard trong smartspace_admin
```
Agent sẽ chấm điểm theo thang Heuristic:
- Nhận diện vấn đề: Quá nhiều thẻ lồng thẻ (Card-in-card), tỷ lệ tương phản chữ xám trên nền xám yếu, viền hairline quá nhiều gây nhiễu thị giác.

#### Bước 2: Tinh chỉnh tinh giản và làm dịu giao diện
```text
Áp dụng design-taste-frontend và /impeccable quieter để dọn dẹp các đường viền hairline, 
thay thế việc phân chia bằng khoảng cách (spacing 16/24px) và màu nền Surface Variant (#EEF4F2 / #1D2A26).
Đồng thời /impeccable bolder các số liệu thống kê quan trọng (Display font 40px, màu Teal đậm).
```

#### Bước 3: Chốt chất lượng trước khi đóng task
```text
/impeccable polish Toàn bộ bố cục và padding của màn hình Dashboard
```

---

### Kịch bản 3: Sửa lỗi hiển thị, Tràn chữ & Edge Cases (Staff App)

**Mục tiêu:** Khi cán bộ hiện trường mở danh sách công việc trên điện thoại màn hình nhỏ, tiêu đề địa chỉ dài bị lỗi tràn pixel (A RenderFlex overflowed...), và khi chưa có sự cố nào thì màn hình chỉ hiện một khoảng trắng trơn.

#### Bước 1: Yêu cầu xử lý Edge Cases & Copy chữ
```text
/impeccable harden Danh sách công việc của Staff:
1. Xử lý text overflow bằng TextOverflow.ellipsis và hiển thị tooltip hoặc mở rộng khi bấm vào.
2. Xây dựng Empty State chuẩn theo DESIGN.md (Icon dịu mắt, thông điệp rõ ràng "Chưa có nhiệm vụ mới", nút "Làm mới danh sách").
3. /impeccable clarify: Viết lại các thông báo trạng thái ngắn gọn, rõ ràng theo tiếng Việt và tiếng Anh.
```

#### Bước 2: Kiểm tra chế độ Dark Mode
```text
/impeccable audit Kiểm tra lại màu nền Surface (#17211E) và màu chữ (#E7EFEC) của danh sách này trong Dark Mode để đảm bảo độ tương phản trên 4.5:1.
```

---

## 5. Tóm tắt Những Điều Cần Nhớ (Best Practices)

1. **Luôn gọi lệnh trong Chat với AI:** Không gõ `/impeccable` vào terminal PowerShell (chỉ chạy terminal cho `node lint.mjs` hoặc lệnh build Flutter/Maven).
2. **Không phá vỡ `DESIGN.md`:** Màu sắc, khoảng cách, font chữ phải lấy từ token trong `DESIGN.md` và `app_theme.dart`. Không tự ý hardcode mã màu hex mới vào widget.
3. **Bắt buộc L10n:** Mọi chuỗi văn bản người dùng nhìn thấy phải nằm trong file đa ngôn ngữ (`app_vi.arb` và `app_en.arb`).
4. **Kiểm tra cả 2 chế độ Dark & Light:** Không bao giờ hoàn thành task UI nếu mới chỉ xem trên một giao diện sáng hoặc tối.
5. **Anti-slop là văn hóa:** Luôn ưu tiên khoảng thở (spacing) và sắc độ nền (tonal layering) thay cho các đường kẻ chia cắt (hairlines) và bóng đổ đen sì.

