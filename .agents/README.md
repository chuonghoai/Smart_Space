# AI Agent Skills & Rules System

Hệ thống Skills và Rules trong thư mục `.agents` được thiết kế để chuẩn hóa quy trình làm việc của AI Agent trong dự án SmartSpace, đảm bảo mọi thay đổi về mã nguồn, giao diện (UI), kiến trúc và Pull Request (PR) đều tuân thủ chặt chẽ tiêu chuẩn dự án và diễn ra an toàn.

---

## 1. Source of Truth (Nguồn chân lý kiến trúc)

Mọi thay đổi do AI Agent thực hiện phải tuân thủ các tài liệu kiến trúc gốc theo thứ tự ưu tiên:
1. `app_architecture/` (Kiến trúc ứng dụng Client/Admin/Staff)
2. `backend_architecture/` (Kiến trúc Backend Spring Boot)
3. `app_architecture/design/design.md` (Design tokens, màu sắc, typography chuẩn)
4. `.agents/rules/` và `.agents/skills/` (Quy định hành vi và kỹ năng chuẩn hóa của Agent)

> **Nguyên tắc bảo toàn:** Yêu cầu nghiệp vụ, tính đúng đắn của logic, khả năng tiếp cận (Accessibility) và hệ thống token kiến trúc luôn có độ ưu tiên cao nhất. Thẩm mỹ thiết kế không được phép làm thay đổi hoặc phá vỡ yêu cầu nghiệp vụ.

---

## 2. Cấu trúc thư mục thực tế

```text
.agents/
├── README.md                               # Tài liệu tổng quan hệ thống Agent (file này)
├── rules/                                  # Hệ thống quy tắc dùng chung (Shared Rules)
│   ├── shared-architecture-rules.md        # Ràng buộc kiến trúc & xử lý mâu thuẫn
│   ├── shared-git-rules.md                 # Quy tắc an toàn thao tác Git
│   ├── shared-reporting-rules.md           # Chuẩn format báo cáo & đánh giá mức độ nghiêm trọng
│   ├── shared-ui-l10n-rules.md             # [Always-on] Quy định UI (Dark/Light), L10n & Design Taste
│   └── shared-workflow.md                  # Quy trình 10 bước chuẩn mực (Understand -> Plan -> Execute)
└── skills/                                 # Danh mục các kỹ năng chuyên biệt (Skills)
    ├── design-taste-frontend/              # Thiết kế UI chống rập khuôn (Anti-slop frontend)
    ├── find-skills/                        # Khám phá và cài đặt skill từ skills.sh
    ├── smp-analyzeTask/                    # Phân tích scope, rủi ro, tác động của task
    ├── smp-cleanup/                        # Quét và dọn dẹp file rác trong workspace
    ├── smp-createPR/                       # Chuẩn bị và tạo Pull Request
    ├── smp-createTestCase/                 # Đọc code thực tế và tạo Test Cases
    ├── smp-fixbug/                         # Truy vết root cause và lập kế hoạch sửa bug
    ├── smp-newFeature/                     # Phân tích yêu cầu và lập kế hoạch tính năng mới
    ├── smp-newTesting/                     # Quy chuẩn viết Integration Test Backend & testapi.ps1
    ├── smp-review-code/                    # Review code branch hiện tại so với dev
    ├── smp-reviewPR/                       # Tổng hợp: Review toàn diện và Merge PR
    └── smp-reviewSecurityPerformance/      # Đánh giá an toàn, bảo mật và hiệu năng
```

---

## 3. Hệ thống Rules & Cơ chế nạp (Rules Loading Mechanism)

Các quy tắc trong `.agents/rules/` được phân loại rõ ràng theo cơ chế nạp của Agent:

| Loại Rule | File áp dụng | Cơ chế nạp | Phạm vi & Ràng buộc |
| :--- | :--- | :--- | :--- |
| **Always-on Rule** (Quy tắc tự động) | `shared-ui-l10n-rules.md` | Tự động nhúng vào prompt (`trigger: always_on`) | Bắt buộc đối với mọi lượt tương tác: Dark/Light mode, Localization, và ràng buộc áp dụng `design-taste-frontend`. |
| **Explicit Dependency Rules** (Quy tắc phụ thuộc) | `shared-workflow.md`<br>`shared-architecture-rules.md`<br>`shared-git-rules.md`<br>`shared-reporting-rules.md` | Nạp theo liên kết tường minh trong từng `SKILL.md` | Bắt buộc khi thực thi các skill có khai báo dependency tương ứng (ví dụ: `smp-newFeature`, `smp-fixbug`, `smp-reviewPR`). |

---

## 4. Danh sách Skills

| Command / Skill | Purpose | Input | Sửa code | Sửa Git | Xác nhận (Approval) |
| :--- | :--- | :--- | :---: | :---: | :---: |
| `/smp-newFeature` | Phân tích và lập kế hoạch tính năng mới | Mô tả tính năng | Có (khi user cho phép) | Không | **Có** (cho Implementation Plan) |
| `/smp-fixbug` | Phân tích root cause và lập kế hoạch sửa bug | Mô tả lỗi | Có (khi user cho phép) | Không | **Có** (cho Implementation Plan) |
| `/smp-analyzeTask` | Phân tích scope, rủi ro và tác động kiến trúc/UI | Mô tả task | Không | Không | Không |
| `/smp-review-code` | Review branch hiện tại so với `dev` (Functional, Arch, Quality, Design) | Branch name / Không | Không | Không | Không |
| `/smp-reviewPR` | **Tổng hợp:** Review toàn diện và Merge PR | Branch name | Không | Có (merge, xóa branch) | **CÓ** (trước khi Merge) |
| `/smp-reviewSecurityPerformance` | Đánh giá an toàn, bảo mật và hiệu năng | Branch name | Không | Không | Không |
| `/smp-createPR` | Push code và tạo Pull Request lên remote | Không | Không | Có (push) | Không (chỉ tạo PR) |
| `/smp-createTestCase` | Đọc code thực tế để tạo Test Cases | Không / Mô tả | Không | Không | Không |
| `/smp-newTesting` | Viết integration test backend & cấu hình `testapi.ps1` | Tên API / Flow | Có (khi user cho phép) | Không | **Có** (cho plan test) |
| `/smp-cleanup` | Quét và dọn dẹp file rác trong workspace | Không | Không (chỉ xóa rác) | Không | **Có** (trước khi xóa file) |
| `design-taste-frontend` | Hướng dẫn thiết kế frontend chất lượng cao, chống AI-slop | Brief UI / Yêu cầu thiết kế | Có (áp dụng trong code UI) | Không | Theo quy trình của task |
| `find-skills` | Tìm kiếm và cài đặt thêm skill từ hệ sinh thái [skills.sh](https://skills.sh/) | Câu hỏi / Từ khóa tìm kiếm | Không | Không | **Có** (trước khi cài đặt) |

---

## 5. Tích hợp Design Taste Skill (`design-taste-frontend`)

Skill `design-taste-frontend` là bộ tiêu chuẩn thiết kế frontend chống rập khuôn (Anti-slop) dành riêng cho việc tạo mới, xây dựng và cải tiến giao diện.

### 5.1. Khi nào BẮT BUỘC áp dụng?
- **Tạo mới UI / Màn hình / Component:** Khi thực hiện `/smp-newFeature` hoặc tạo mới giao diện, Agent **MUST** đọc và áp dụng `design-taste-frontend/SKILL.md`:
  1. **Brief Inference (Đọc tín hiệu):** Phân tích Page kind, Vibe, Audience, Quiet constraints.
  2. **Design Read:** Bắt buộc xuất 1 dòng tuyên bố định hướng trước khi code:  
     `Reading this as: <page kind> for <audience>, with a <vibe> language, leaning toward <design system or aesthetic family>.`
  3. **The Three Dials:** Thiết lập 3 thông số định hình giao diện: `DESIGN_VARIANCE`, `MOTION_INTENSITY`, `VISUAL_DENSITY`.
  4. **Anti-Default Discipline:** Tránh các pattern AI rập khuôn (không dùng gradient tím AI mặc định, không chia 3 card đều nhau vô hồn, không glassmorphism tràn lan, không dùng mặc định Inter + slate-900).

### 5.2. Khi nào áp dụng GIỚI HẠN (Sửa lỗi UI / Fix bug)?
- Khi thực hiện `/smp-fixbug` hoặc chỉnh sửa nhỏ liên quan đến UI:
  - Agent chỉ áp dụng các quy tắc thiết kế cục bộ cần thiết để giải quyết lỗi.
  - **TUYỆT ĐỐI KHÔNG** tự ý redesign toàn bộ màn hình, thay đổi layout tổng thể hoặc mở rộng phạm vi sửa lỗi ngoài yêu cầu của bug.

### 5.3. Khi nào KHÔNG CẦN áp dụng?
- Các tác vụ hoàn toàn liên quan đến Backend (Spring Boot), Database, CI/CD, Unit Test logic, hoặc Refactor mã nguồn không có giao diện hiển thị.

### 5.4. Nguyên tắc minh bạch & Xác minh
- Việc chỉ nhắc đến tên skill `design-taste-frontend` **không** được tính là đã tuân thủ. Agent phải sử dụng các chỉ dẫn cụ thể trong file `SKILL.md`.
- Nếu Agent gặp lỗi không đọc được skill, phải báo rõ ràng cho người dùng, không được tự ý tuyên bố đã tuân thủ.

---

## 6. Mối quan hệ phối hợp (Dependency & Workflow)

```text
/smp-reviewPR
    ├── /smp-review-code
    │   ├── Shared Architecture Rules
    │   ├── Shared Reporting Rules
    │   ├── Shared UI & Localization Rules (Always-on)
    │   └── design-taste-frontend (Kiểm tra tiêu chí thiết kế chống AI-slop)
    ├── /smp-reviewSecurityPerformance
    │   ├── Shared Architecture Rules
    │   └── Shared Reporting Rules
    └── Shared Git Rules (Xử lý an toàn Merge & Xóa branch)

/smp-newFeature
    ├── Shared Workflow
    ├── Shared Architecture Rules
    ├── Shared UI & Localization Rules (Always-on)
    └── design-taste-frontend (Bắt buộc khi tính năng có UI mới)

/smp-fixbug
    ├── Shared Workflow
    ├── Shared Architecture Rules
    ├── Shared UI & Localization Rules (Always-on)
    └── design-taste-frontend (Chỉ áp dụng cục bộ trong phạm vi bug, không tự ý redesign)
```

---

## 7. Các thao tác bắt buộc xin xác nhận (User Confirmation)

Agent **KHÔNG ĐƯỢC** tự ý thực hiện các hành động sau nếu chưa có sự phê duyệt rõ ràng từ người dùng:
1. **Viết code mới hoặc sửa code:** Phải xuất trình Implementation Plan và chờ user xác nhận mới bắt đầu chỉnh sửa file.
2. **Merge PR:** Phải hoàn thành Audit Report và chờ user gõ lệnh đồng ý mới tiến hành merge vào branch chính (`dev`).
3. **Xóa file:** Trong quá trình dọn dẹp (`/smp-cleanup`), nếu không chắc chắn 100% là file rác thì phải hỏi ý kiến user.
4. **Bypass Architecture:** Bất kỳ giải pháp nào đi ngược lại hoặc vượt ra ngoài tài liệu kiến trúc chuẩn đều phải xin phép trước.
5. **Cài đặt Skill mới:** Khi dùng `find-skills` để bổ sung skill, phải hỏi ý kiến user trước khi chạy lệnh cài đặt (`npx skills add`).

---

## 8. Cơ chế kích hoạt & Giới hạn kỹ thuật đã xác minh

1. **Nhận diện tự động:** Antigravity IDE tự động nhận diện tất cả các skill đặt trong thư mục `.agents/skills/<tên_skill>/SKILL.md` của workspace và nạp rule có `trigger: always_on` trong `.agents/rules/`.
2. **Quyền truy cập:** Các file trong phạm vi workspace dự án (`d:\study\ute\4 - HK1\TieuLuanChuyenNganh\SmartSpace\...`) hoàn toàn có quyền đọc/ghi bởi agent.
3. **Gọi lệnh (Slash commands):** Người dùng có thể gọi trực tiếp các lệnh `/smp-*` hoặc yêu cầu Agent thực thi nhiệm vụ theo ngôn ngữ tự nhiên. Agent sẽ tự động đối chiếu các rule và skill tương ứng.
