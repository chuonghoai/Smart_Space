---
name: SmartSpace Design System
description: Hệ thống thiết kế chuẩn cho nền tảng SmartSpace (Teal + Green, Realtime WebSocket, Đa nền tảng Flutter & Web)
colors:
  primary: "#00796B"
  primary-light: "#26A69A"
  primary-dark: "#004D40"
  secondary: "#558B2F"
  background-light: "#F5F8F7"
  surface-light: "#FFFFFF"
  surface-variant-light: "#EEF4F2"
  background-dark: "#0F1715"
  surface-dark: "#17211E"
  surface-variant-dark: "#1D2A26"
  text-primary-light: "#17201E"
  text-secondary-light: "#52615D"
  text-muted-light: "#7A8783"
  text-primary-dark: "#E7EFEC"
  text-secondary-dark: "#B4C2BE"
  text-muted-dark: "#899A95"
  border-light: "#D8E2DF"
  border-strong-light: "#B8C9C4"
  border-dark: "#30403B"
  border-strong-dark: "#42554F"
  divider-light: "#E5ECEA"
  divider-dark: "#273631"
  success-light: "#2E7D32"
  success-dark: "#66BB6A"
  warning-light: "#F9A825"
  warning-dark: "#FFCA28"
  error-light: "#C62828"
  error-dark: "#EF5350"
  info-light: "#1565C0"
  info-dark: "#42A5F5"
typography:
  display:
    fontSize: "44px"
    lineHeight: 1.2
    fontWeight: 700
  headline:
    fontSize: "30px"
    lineHeight: 1.25
    fontWeight: 700
  title:
    fontSize: "22px"
    lineHeight: 1.3
    fontWeight: 600
  subtitle:
    fontSize: "18px"
    lineHeight: 1.4
    fontWeight: 500
  body-large:
    fontSize: "16px"
    lineHeight: 1.5
    fontWeight: 400
  body:
    fontSize: "14px"
    lineHeight: 1.5
    fontWeight: 400
  body-small:
    fontSize: "13px"
    lineHeight: 1.45
    fontWeight: 400
  caption:
    fontSize: "12px"
    lineHeight: 1.4
    fontWeight: 400
rounded:
  sm: "4px"
  md: "8px"
  lg: "12px"
  xl: "16px"
  full: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  base: "16px"
  lg: "20px"
  xl: "24px"
  "2xl": "32px"
  "3xl": "48px"
  "4xl": "64px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface-light}"
    rounded: "{rounded.md}"
    padding: "12px 24px"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.primary}"
    rounded: "{rounded.md}"
    padding: "12px 24px"
  card:
    backgroundColor: "{colors.surface-light}"
    rounded: "{rounded.lg}"
    padding: "16px"
---

# SmartSpace UI Design System

## Overview

SmartSpace là nền tảng hướng về cộng đồng phục vụ cho việc phản ánh, điều phối và giám sát thời gian thực các vấn đề môi trường, cơ sở hạ tầng và an toàn đô thị.

Giao diện người dùng của SmartSpace truyền tải các giá trị cốt lõi:
- **Trust (Tin cậy):** Người dùng cảm nhận được các phản ánh và dữ liệu thông tin được tiếp nhận, xử lý chuẩn xác, minh bạch.
- **Clarity (Rõ ràng):** Người dùng lập tức hiểu rõ họ có thể làm gì và điều gì đang diễn ra trên hệ thống.
- **Calm (Điềm tĩnh):** Giảm thiểu tối đa tiếng ồn thị giác (visual noise), tránh màu sắc gắt hoặc hoạt ảnh phô trương không cần thiết.
- **Action-oriented (Hành động nhanh):** Quy trình tạo phản ánh sự cố phải nhanh chóng, hiển thị trực quan và tối thiểu số bước chạm.
- **Community awareness (Ý thức cộng đồng):** Ngôn ngữ thị giác gần gũi, văn minh và mang tính trách nhiệm xã hội.
- **Accessibility (Tiếp cận toàn diện):** Mọi thông tin đều rõ ràng, dễ tiếp cận trên mọi thiết bị, mọi chế độ ánh sáng.

Nhận diện thị giác được xây dựng trên bộ đôi **Teal + Green**, kết hợp giữa tính công nghệ, độ tin cậy và ý thức sinh thái / môi trường xanh.

Thiết kế bắt buộc hỗ trợ đầy đủ cả **Light Mode** và **Dark Mode** ngay từ đầu. Không thiết kế Light Mode trước rồi xem Dark Mode là thứ yếu; cả hai chế độ đều có vai trò màu sắc chủ đích và độ tương phản đạt chuẩn.

### Thứ tự ưu tiên thiết kế (Design Priority)
Khi có xung đột trong các quyết định thiết kế, bắt buộc ưu tiên theo thứ tự:
1. **Accessibility** (Khả năng tiếp cận)
2. **Usability** (Tính khả dụng, tiện dụng)
3. **Clarity** (Sự rõ ràng)
4. **Trust and reliability** (Độ tin cậy và minh bạch)
5. **Consistency** (Tính nhất quán)
6. **Visual aesthetics** (Tính thẩm mỹ thị giác)

*Tuyệt đối không chọn một giải pháp đẹp mắt nếu giải pháp đó làm cho quy trình phản ánh của người dân trở nên rối rắm hoặc khó tiếp cận.*

### Triết lý thiết kế (Design Philosophy)
SmartSpace mang lại cảm giác: **Đáng tin cậy, điềm tĩnh, rõ ràng, hiện đại và hướng về cộng đồng.**
Không mang lại cảm giác: Quá khô khan quan liêu, mang tính mạng xã hội giải trí, hào nhoáng như game, hoặc phô trương thị giác.

---

## Colors

### Brand Colors
- **Primary:** `#00796B` (Teal) — Màu thương hiệu chính. Dùng cho nút CTA chính, active navigation, selection, focus indicators, thanh tiến trình chính và các liên kết quan trọng. Không dùng Primary làm màu trang trí vô tội vạ.
- **Primary Light:** `#26A69A` — Dùng trong Dark Mode cho primary text/interactive elements hoặc highlight nhẹ.
- **Primary Dark:** `#004D40` — Dùng cho các bề mặt nhấn mạnh hoặc surface trong Dark Mode.
- **Secondary:** `#558B2F` (Green) — Tượng trưng cho ý thức môi trường, sinh thái xanh và hành động cộng đồng. Sử dụng chọn lọc cho các điểm nhấn môi trường, danh mục xanh, icon hỗ trợ. Không dùng Secondary để thay thế trạng thái Success ngữ nghĩa.

### Semantic Colors
Màu ngữ nghĩa truyền tải ý nghĩa trạng thái thực tế của hệ thống, không dùng làm màu trang trí:
- **Success:**
  - Light: `#2E7D32` | Dark: `#66BB6A`
  - Dùng cho: Phản ánh đã gửi thành công, sự cố đã giải quyết, thao tác hoàn thành, API thành công.
- **Warning:**
  - Light: `#F9A825` | Dark: `#FFCA28`
  - Dùng cho: Phản ánh đang chờ tiếp nhận/xử lý, yêu cầu bổ sung thông tin, trạng thái cần chú ý tạm thời.
- **Error:**
  - Light: `#C62828` | Dark: `#EF5350`
  - Dùng cho: Lỗi xác thực biểu mẫu, thao tác thất bại, hành động hủy/xóa, phản ánh bị từ chối, cảnh báo nguy cấp.
- **Info:**
  - Light: `#1565C0` | Dark: `#42A5F5`
  - Dùng cho: Thông điệp giải thích, thông tin hệ thống, trạng thái trung tính.

> **Quy tắc màu ngữ nghĩa:** Không dùng màu đỏ hay cam tùy tiện chỉ vì phản ánh liên quan đến an ninh hay hạ tầng. Ví dụ: Phản ánh an ninh bình thường dùng Primary/Neutral; phản ánh đã nộp dùng Success; phản ánh bị từ chối dùng Error.

### Surfaces & Text (Light Theme)
- **Background:** `#F5F8F7` (Nền chính dịu mắt, tránh dùng màu trắng tinh `#FFFFFF` toàn màn hình)
- **Surface:** `#FFFFFF` (Dùng cho Cards, Dialogs, Navigation bars, Elevated surfaces)
- **Surface Variant:** `#EEF4F2` (Dùng cho container phụ, input background mờ)
- **Input Background:** `#FFFFFF`
- **Text Primary:** `#17201E` (Tránh màu đen thuần `#000000`)
- **Text Secondary:** `#52615D`
- **Text Muted:** `#7A8783`
- **Text On Primary:** `#FFFFFF`
- **Border:** `#D8E2DF`
- **Border Strong:** `#B8C9C4`
- **Divider:** `#E5ECEA`

### Surfaces & Text (Dark Theme)
Dark Mode không được triển khai bằng cách đảo màu cơ học; phải sử dụng các bề mặt tối có sự phân tách rõ rệt:
- **Background:** `#0F1715` (Tránh nền đen tuyền `#000000`)
- **Surface:** `#17211E`
- **Surface Variant:** `#1D2A26`
- **Input Background:** `#1A2522`
- **Text Primary:** `#E7EFEC`
- **Text Secondary:** `#B4C2BE`
- **Text Muted:** `#899A95`
- **Text On Primary:** `#FFFFFF`
- **Border:** `#30403B`
- **Border Strong:** `#42554F`
- **Divider:** `#273631`
- **Dark Mode Primary:** Dùng `#26A69A` hoặc `#4DB6AC` trên nền tối để đảm bảo độ tương phản cao, không dùng `#00796B` chìm trên nền tối.

### Nguồn chuẩn màu và Quy tắc Code (Theme Source of Truth)
- File `app_theme.dart` (trong `mobile_shared` hoặc từng app) là nguồn chân lý (Source of Truth) cho toàn bộ màu sắc và theme tokens trong code Flutter.
- UI code **BẮT BUỘC** tiêu thụ màu từ `ThemeData`, `ColorScheme` hoặc theme extension của dự án.
- **CẤM HARDCODE MÀU:** Tuyệt đối không dùng `Colors.xxx`, `Color(0x...)`, `Color.fromARGB(...)`, `Color.fromRGBO(...)` hoặc mã hex trực tiếp trong Widget nếu đã có theme token tương ứng.
- **Tính đầy đủ Light/Dark:** Mọi token màu tùy chỉnh mới đều BẮT BUỘC phải định nghĩa cả 2 biến thể Light và Dark trước khi đưa vào sử dụng trong widget.
- Không dùng màu sắc làm phương tiện duy nhất để truyền đạt thông tin quan trọng.

---

## Typography

Typography ưu tiên khả năng đọc rõ ràng, phân cấp mạch lạc hơn là trang trí kiểu cách.

### Font Family
- Sử dụng font sans-serif hiện đại, sạch sẽ được cấu hình thống nhất trong dự án (Roboto trên Android, San Francisco trên iOS, hoặc font sans-serif tiêu chuẩn của hệ thống).
- Tránh phối hợp nhiều họ font không liên quan trong cùng ứng dụng.

### Thang đo Type Scale
- **Display:** `40–48px` (Line height: 1.2, Weight: Bold) — Số liệu thống kê lớn, tiêu đề chào mừng nổi bật.
- **Headline:** `28–32px` (Line height: 1.25, Weight: Bold) — Tiêu đề màn hình chính.
- **Title:** `22–24px` (Line height: 1.3, Weight: SemiBold) — Tiêu đề danh mục, tiêu đề card phản ánh, tên địa điểm.
- **Subtitle:** `18px` (Line height: 1.4, Weight: Medium) — Tiêu đề nhóm form, tên người dùng.
- **Body Large:** `16px` (Line height: 1.5, Weight: Regular/Medium) — Nội dung phản ánh quan trọng, ô nhập liệu chính.
- **Body:** `14–15px` (Line height: 1.5, Weight: Regular) — Văn bản mô tả tiêu chuẩn, thông tin chi tiết.
- **Body Small:** `13px` (Line height: 1.45, Weight: Regular) — Thông tin phụ trợ, chú thích trạng thái.
- **Caption:** `12px` (Line height: 1.4, Weight: Regular/Medium) — Timestamp (thời gian), nhãn thẻ, metadata nhỏ.

### Quy tắc Typography
- Phân cấp rõ rệt giữa Tiêu đề và Nội dung.
- Ưu tiên 3 mức độ trọng số (Font Weights): Regular (400), Medium (500), SemiBold/Bold (600/700). Tránh lạm dụng quá nhiều weight.
- Tránh viết hoa toàn bộ (ALL-CAPS) cho các đoạn văn bản dài.
- Trên nền tảng di động, đơn vị font phải theo `sp` (scale-independent pixels) để tôn trọng cài đặt kích thước chữ của hệ điều hành.

---

## Layout

### Hệ thống Spacing (Base 4px)
Toàn bộ khoảng cách tuân thủ hệ số của **4px**:
`4px`, `8px`, `12px`, `16px`, `20px`, `24px`, `32px`, `40px`, `48px`, `64px`, `80px`, `96px`.
- Khoảng cách nội bộ nhỏ (trong chip, nút nhỏ): `8px`.
- Khoảng cách nội bộ tiêu chuẩn (padding card, input): `12–16px`.
- Khoảng cách nội bộ lớn: `20–24px`.
- Khoảng cách giữa các section: `32–48px`.
- Khoảng cách giữa các khối lớn: `48–64px`.
- Lề an toàn màn hình di động: `16px`.

### Thiết kế Responsive (Mobile & Web)
- **Mobile (Client & Staff):**
  - Là ngữ cảnh tương tác chính.
  - Tối ưu thao tác bằng một tay.
  - Vùng chạm (Touch Target) tối thiểu **48x48 dp** với khoảng cách tối thiểu **8 dp** giữa các điểm chạm.
  - Giảm thiểu độ sâu của cây điều hướng, đưa hành động tạo phản ánh ra vị trí dễ tiếp cận nhất.
- **Web / Desktop (Admin):**
  - Khai thác hiệu quả không gian ngang qua bố cục đa cột.
  - Thanh điều hướng cố định (Sidebar bên trái hoặc Top bar).
  - Bản đồ chiếm không gian lớn kèm bảng dữ liệu (Data table) có lọc và tìm kiếm.
  - Không kéo giãn (stretch) giao diện mobile một cách thô thiển lên màn hình desktop.

### Kiến trúc Responsive trong Code
Cấu trúc phân lớp trách nhiệm rõ ràng:
```text
Responsive Screen
    ↓
Mobile / Web UI
    ↓
Controller
    ↓
Service
    ↓
Repository
```
Wrapper responsive chỉ làm nhiệm vụ chọn UI theo kích thước màn hình; không truyền state phức tạp hay callback dài dòng qua wrapper.

### Bản đồ và Định vị (Maps & Location)
- Bản đồ hỗ trợ đắc lực cho quy trình phản ánh nhưng không được làm lộn xộn giao diện.
- Màu Primary được dùng cho vị trí đang chọn, nút điều khiển vị trí hiện tại và điểm đánh dấu active.
- Xử lý gom cụm (Clustering): Khi nhiều điểm phản ánh nằm sát nhau trong phạm vi hẹp, hệ thống mở danh sách chọn các điểm thay vì để các marker đè lên nhau gây khó bấm.
- Dữ liệu vị trí phải hiển thị rõ ràng trên cả 2 theme.

### Điều hướng (Navigation)
- **Mobile:** Bottom navigation bar (3–5 điểm đến chính), Navigation Drawer cho các mục cài đặt/phụ, Floating Action Button (FAB) cho hành động tạo phản ánh duy nhất.
- **Web:** Sidebar cố định, hiển thị rõ ràng trạng thái mục đang active.

---

## Elevation & Depth

Giao diện SmartSpace sử dụng độ sâu kiềm chế, thanh lịch (Restrained Elevation):
- **Phân tách theo sắc độ (Tonal Elevation):** Ưu tiên phân biệt các lớp bằng màu nền bề mặt (Surface / Surface Variant) hơn là lạm dụng bóng đổ (drop shadow).
- **Light Mode:** Dùng viền nhẹ subtle border (`#D8E2DF`) và bóng đổ rất mềm cho các bề mặt nổi; thẻ (card) thông thường ở trạng thái nghỉ không cần đổ bóng dày.
- **Dark Mode:** Dựa hoàn toàn vào sự khác biệt giữa sắc độ nền (`#0F1715`) và bề mặt thẻ (`#17211E`, `#1D2A26`) kèm viền mỏng (`#30403B`). Tuyệt đối không dùng bóng đổ đen kịt trên nền tối.
- Tránh các bóng đổ quá đậm, quá gắt gây phân tâm.

---

## Shapes & Border Radius

Hệ thống bo góc (Border Radius) đồng bộ:
- **`4px` (`rounded.sm`):** Nhãn nhỏ, badge compact, thanh chỉ báo nhỏ.
- **`8px` (`rounded.md`):** Nút bấm, ô nhập liệu (input), thanh tìm kiếm, chip thông thường.
- **`12px` (`rounded.lg`):** Thẻ thông tin (cards), dialog xác nhận, modal nhỏ.
- **`16px` (`rounded.xl`):** Bottom sheet kéo từ dưới lên, container tính năng lớn.
- **`9999px` (`rounded.full`):** Circle avatar, nút tròn FAB, pill badge trạng thái.

Không tự ý đưa vào các giá trị bo góc tùy tiện khi chưa có lý do thiết kế thuyết phục.

---

## Components

### Buttons
- **Primary Button:** Nền Teal `#00796B` (hoặc `#26A69A` ở Dark Mode), chữ trắng, bo góc 8px. Dùng cho hành động quan trọng nhất (VD: `Gửi phản ánh`). Không đặt quá 1 nút Primary trong cùng một vùng nhìn hẹp.
- **Secondary Button:** Nền trong suốt hoặc surface, viền và chữ màu Primary.
- **Ghost Button:** Không viền, không nền, dùng cho hành động phụ ít quan trọng.
- **Destructive Button:** Màu đỏ Error, chỉ dùng cho hành động xóa, từ chối, hủy không thể phục hồi.
- Nhãn nút phải rõ ràng, mang tính hành động (tránh các nhãn chung chung như `OK`, `Click here`, `Submit`).
- Nút disabled phải phân biệt được với nút enabled mà không chỉ dựa vào việc làm mờ màu.
- Nút bấm khi loading phải có chỉ báo rõ ràng (Spinner/Progress) và chặn click đúp.

### Forms & Inputs
- Ô nhập liệu phải có nhãn (Label) rõ ràng bên ngoài, không phụ thuộc hoàn toàn vào placeholder.
- Viền rõ ràng, bo góc 8px, trạng thái focus viền Primary.
- Trạng thái lỗi (Validation Error): Phải hiển thị cả viền đỏ kèm icon và dòng văn bản giải thích lỗi cụ thể, có hướng dẫn cách khắc phục.

### Cards
- Nền Surface, viền mỏng subtle border, bo góc 12px, không lạm dụng shadow.
- Dùng cho tóm tắt phản ánh, thông báo, nhóm hành động liên quan.
- Không bọc mọi thành phần vào từng card riêng lẻ gây vụn vỡ giao diện.

### Trạng thái phản ánh (Status Indicators)
Mọi trạng thái phản ánh BẮT BUỘC phải đi kèm Text nhãn rõ ràng, không biểu thị trạng thái chỉ bằng màu sắc:
- `Đã gửi` → **Success**
- `Đang xử lý` → **Warning**
- `Đã xử lý` → **Success**
- `Từ chối` → **Error**
- `Cần bổ sung thông tin` → **Warning**
- `Thông tin` → **Info**

### Chips & Badges
- Dùng để phân loại sự cố (Môi trường, Hạ tầng, An ninh...), bộ lọc (Filters), trạng thái.
- Sử dụng màu ngữ nghĩa nhất quán. Không dùng quá nhiều chip dạng pill rải rác khắp màn hình.

### Quy trình Tạo Phản ánh (Report Creation UI)
Quy trình cốt lõi của người dân gồm 7 bước ưu tiên:
1. Chọn loại phản ánh (Môi trường, Cơ sở hạ tầng, Trật tự công cộng...)
2. Chụp ảnh hoặc tải lên bằng chứng hiện trường
3. Nhập mô tả thông tin sự cố
4. Xác nhận / chọn vị trí trên bản đồ số
5. Xem lại thông tin tóm tắt
6. Gửi phản ánh
7. Hiển thị thông báo trạng thái gửi thành công tức thời

*Người dùng luôn biết họ đang ở bước nào, thông tin nào là bắt buộc, thông tin nào là tùy chọn.*

### Hoạt ảnh & Chuyển động (Motion & Animation)
- Hoạt ảnh phải tinh tế, có mục đích và ngắn gọn:
  - Tương tác vi mô (Micro-interaction, button tap): `100–150ms`.
  - Chuyển trang/chuyển tab tiêu chuẩn: `150–250ms`.
  - Mở modal/bottom sheet: `250–350ms`.
- Tôn trọng thiết lập "Reduce Motion" của hệ thống.
- Tuyệt đối không dùng hoạt ảnh vô tận gây xao nhãng hoặc làm chậm trễ thao tác gửi phản ánh.

### Trạng thái tải, rỗng và lỗi (Loading, Empty & Error States)
- **Loading:** Tránh màn hình trắng trơn. Ưu tiên Skeleton loading giữ khung layout hoặc Progress Indicator rõ ràng kèm thông báo khi tác vụ kéo dài.
- **Empty State:** Giải thích rõ: (1) Cái gì đang trống, (2) Vì sao trống, (3) Hành động tiếp theo là gì (kèm nút hành động cụ thể).
- **Error State:** Điềm tĩnh, rõ ràng, có nút "Thử lại". Tuyệt đối không ném lỗi kỹ thuật thô (stack trace, exception, mã lỗi HTTP) ra màn hình người dùng.

---

## Do's and Don'ts

### Do's (NÊN LÀM)
- **MUST** thiết kế đồng thời và kiểm tra tương phản ở cả Light Mode và Dark Mode.
- **MUST** sử dụng 100% hệ thống L10n (`AppLocalizations`) cho toàn bộ text hiển thị (cả tiếng Việt và tiếng Anh).
- **MUST** tiêu thụ màu từ `app_theme.dart` / theme tokens, đảm bảo token mới có đủ 2 bản Light và Dark.
- **MUST** đảm bảo touch target trên mobile tối thiểu 48x48 dp.
- **MUST** tuân thủ thang spacing 4px và tạo khoảng thở tự nhiên thay vì kẻ quá nhiều đường kẻ hairline ngăn cách.
- **MUST** đưa ra 1 dòng "Design Read" và thiết lập các dial hợp lý khi tạo mới màn hình theo tiêu chuẩn Taste Skill.
- **MUST** bảo toàn tính năng và logic nghiệp vụ hiện có khi sửa lỗi hoặc tinh chỉnh UI.

### Don'ts (TUYỆT ĐỐI TRÁNH)
- **KHÔNG** dùng gradient tím-xanh rập khuôn AI (AI-slop defaults).
- **KHÔNG** đảo ngược màu một cách cơ học khi làm Dark Mode.
- **KHÔNG** dùng màu đen thuần `#000000` hoặc trắng tinh `#FFFFFF` làm toàn bộ background.
- **KHÔNG** lạm dụng màu ngữ nghĩa (đỏ/cam) để trang trí cho các báo cáo bình thường.
- **KHÔNG** hardcode màu hex, font size, hoặc text string trực tiếp trong widget.
- **KHÔNG** để marker bản đồ đè lên nhau mà không có cơ chế gom cụm hoặc mở danh sách.
- **KHÔNG** lạm dụng bóng đổ quá gắt hoặc hoạt ảnh nhảy nhót vô tận.
- **KHÔNG** kéo giãn trực tiếp layout mobile sang desktop mà không tái cấu trúc bố cục.
