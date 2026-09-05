# Feature Development Workflow & Definition of Done

Bất kỳ AI Agent nào khi triển khai một tính năng mới hoặc chỉnh sửa tính năng hiện tại, đều phải tuân thủ quy trình dưới đây.

## Workflow 12 Bước

1. Đọc kỹ tài liệu trong thư mục `AI_SKILLS`.
2. Inspect tính năng và code hiện có tương tự trong project.
3. Xác định cấu trúc UI (Mobile/Web).
4. Xác định Controller (dùng chung cho Mobile/Web).
5. Xác định Service.
6. Xác định Repository.
7. Xác định Model.
8. Kiểm tra và lên danh sách các chuỗi Localization cần thiết.
9. Xác định Navigation flow.
10. Bắt đầu implement code.
11. Chạy `flutter gen-l10n` nếu có cập nhật ngôn ngữ.
12. Analyze (sử dụng `flutter analyze`) và Test code.

---

## Definition of Done (DoD) Checklist

Trước khi coi một feature là hoàn thành, Agent **PHẢI** check các tiêu chí sau:

- [ ] Đã đọc `AI_SKILLS` trước khi triển khai.
- [ ] Đã inspect code/feature tương tự trước khi tạo implementation mới.
- [ ] UI Mobile/Web được tổ chức đúng architecture hiện tại (`mobile/`, `web/`, `responsive/`).
- [ ] Nếu logic Mobile/Web giống nhau, sử dụng chung Controller.
- [ ] Controller / Service / Repository phân định trách nhiệm đúng layer (Dependency flow một chiều: UI -> Controller -> Service -> Repo -> API).
- [ ] Không tạo duplicate Service / Repository / Model nếu đã có implementation có thể reuse.
- [ ] **Không hardcode** user-facing text trên UI.
- [ ] Localization đã được thêm đầy đủ cho cả EN và VN (`app_en.arb`, `app_vi.arb`) theo convention hiện tại.
- [ ] Đã chạy `flutter gen-l10n` sau khi thay đổi localization.
- [ ] Navigation (`go`/`push`/`pop`/`pushReplacement`) được gọi phù hợp với mục đích luồng ứng dụng.
- [ ] Loading/Error/Success state được xử lý đầy đủ khi feature có asynchronous operation.
- [ ] Animation logic được đặt ở Controller hoặc UI theo đúng convention của project.
- [ ] Không tạo ra code hoặc file architecture thừa thãi, không cần thiết.
- [ ] Không tự ý refactor các module/tính năng không liên quan.
- [ ] Đã kiểm tra đầy đủ các thư viện import và quy tắc null-safety.
- [ ] Đã chạy `flutter analyze` và đảm bảo không có cảnh báo/lỗi logic nghiêm trọng.
- [ ] Đã chạy các bộ test liên quan (nếu project có áp dụng).

---

## Rule: Responsive UI Architecture

Khi triển khai code trong các file `responsive`, responsive layer chỉ chịu trách nhiệm lựa chọn và render UI tương ứng (`mobile`, `web`,...). Không truyền các giá trị runtime/state/dependency từ responsive screen vào UI thông qua constructor, trừ khi task explicitly yêu cầu.

Responsive screen không nên quản lý controller, TextEditingController, FocusNode, AnimationController, form state, checkbox state hoặc các UI-specific state chỉ để truyền xuống child UI.

Ưu tiên kiến trúc:

`Responsive → Mobile/Web UI → Controller → Service → Repository`

Responsive layer phải giữ code tối giản, dễ đọc và không trở thành nơi quản lý state của UI.

---

## Rule: UI Dependency Ownership

Các file giao diện (`mobile`, `web`, `desktop`,...) phải tự import và khởi tạo các biến/object/dependency mà chính UI đó sở hữu.

Không yêu cầu responsive layer truyền dependency vào UI thông qua constructor nếu dependency đó chỉ phục vụ riêng UI.

Các object có lifecycle thuộc widget, ví dụ:

* `TextEditingController`
* `ScrollController`
* `FocusNode`
* `AnimationController`
* feature-specific controller

phải được tạo và dispose ở widget sở hữu chúng, trừ khi kiến trúc hoặc task explicitly yêu cầu dependency injection từ bên ngoài.

State chỉ phục vụ một UI cụ thể cũng phải được quản lý tại UI đó.

---

## Rule: UI Constructor

Không sử dụng constructor của các file UI để nhận một danh sách lớn controller, state, callback hoặc object chỉ nhằm truyền dependency từ responsive layer xuống UI.

UI widget phải tự tạo và quản lý dependency của nó khi phù hợp.

Constructor chỉ nên chứa các parameter thực sự cần thiết từ parent hoặc được task yêu cầu truyền từ bên ngoài.

Không tạo constructor dependency injection một cách máy móc.

---

## Rule: Model JSON

Khi tạo một file `model`, phải triển khai đầy đủ hai phương thức chuyển đổi JSON:

```dart
factory Model.fromJson(Map<String, dynamic> json)
```

và

```dart
Map<String, dynamic> toJson()
```

`fromJson` dùng để chuyển JSON/API response thành model.

`toJson` dùng để chuyển model thành JSON/API request hoặc payload.

Không tạo model mới chỉ có properties/constructor mà bỏ qua `fromJson` hoặc `toJson`, trừ khi task explicitly yêu cầu model không serialize/deserialize JSON.

Ví dụ:

```dart
class UserModel {
  final String id;
  final String email;

  UserModel({
    required this.id,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
    };
  }
}
```
