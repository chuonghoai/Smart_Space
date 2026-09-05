# Shared UI & Localization Rules

Mọi thay đổi liên quan đến Giao diện người dùng (UI) và Text hiển thị (User-facing text) MUST tuân thủ nghiêm ngặt các quy định sau đây. 
Không có ngoại lệ. Các quy định này áp dụng cho mọi tác vụ: Feature mới, Bug fix, Code review, UI refactor, UI redesign, PR review.

## 1. DESIGN / DARK MODE & LIGHT MODE

Mọi UI được tạo mới hoặc chỉnh sửa MUST hỗ trợ đúng cả hai chế độ: Light Mode và Dark Mode.

- **MUST NOT** hardcode màu theo cách gây lỗi tương phản giữa hai mode (ví dụ: chữ màu đen trên nền tối trong Dark Mode, chữ màu trắng trên nền sáng trong Light Mode).
- **MUST NOT** sử dụng icon hoặc một thành phần có màu tối trên nền tối khiến khó nhìn.
- **MUST NOT** dùng trực tiếp một màu cố định (fixed color) thay vì màu/theme token nếu project đã có theme/color token tương ứng.
- **MUST** kiểm tra theme hiện tại của project trước khi tạo/chỉnh sửa UI.
- **MUST** ưu tiên sử dụng hệ thống màu/theme/design token (cho Background, text, icon, border, divider, button, input, card...) đã có trong project phù hợp với theme hiện hành.
- **MUST** đảm bảo khi thêm màu mới, màu đó phù hợp và hiển thị tốt ở cả Light Mode và Dark Mode.
- **MUST** kiểm tra trực tiếp các trường hợp tương phản giữa foreground và background ở cả 2 mode (không chỉ kiểm tra syntax/compile) trong quá trình thiết kế, code và review.
- **MUST NOT** thay đổi màu để fix một mode nhưng làm hỏng mode còn lại.
- **Khi code review / PR review**: Nếu phát hiện UI chỉ đúng ở một theme, hoặc một component bị mất tương phản/khó đọc ở mode còn lại, hoặc hardcode màu sai quy tắc, Agent MUST đánh dấu đó là lỗi và yêu cầu fix.

## 2. LANGUAGE / LOCALIZATION (L10N)

Toàn bộ text hiển thị cho người dùng (user-facing text) MUST sử dụng hệ thống L10n/localization của project.

- **MUST NOT** hardcode UI text. Không được viết trực tiếp string vào code như `Text("Đăng nhập")` hoặc `Text("Login")`.
- **MUST** sử dụng cơ chế L10n hiện có của project cho mọi user-facing text (bao gồm: Text widget/component, Button label, AppBar title, Dialog, Snackbar/Toast, Error message, Validation message, Empty state, Loading state, Tooltip, Placeholder, Form label, Confirmation message, Permission message, Notification text, Accessibility/semantic label, và bất kỳ text nào sinh ra trong các state khác nhau).
- **Phân biệt String**: User-facing text MUST được L10n. Internal technical string, log, debug string không hiển thị cho user thì không bắt buộc L10n.
- **MUST** tìm kiếm và sử dụng localization key hiện có trước khi tạo key mới (để tránh tạo duplicate localization key).
- **MUST** bổ sung đầy đủ text mới vào hệ thống L10n theo convention hiện tại của project khi cần text mới.
- **MUST** đảm bảo text mới có đầy đủ translation theo các locale mà project đang hỗ trợ.
- **Khi code review / PR review**: Agent MUST kiểm tra và phát hiện các hardcoded user-facing strings. Nếu phát hiện hardcoded user-facing text, Agent MUST coi đó là lỗi cần fix.
