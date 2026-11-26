# Quy tắc UI Layer

Project hỗ trợ nhiều nền tảng nên UI được phân tách cấu trúc rõ ràng:

### 1. Phân chia thư mục
Thư mục UI được chia thành:
- `mobile/`: Chứa giao diện dành riêng cho Mobile.
- `web/`: Chứa giao diện dành riêng cho Web.
- `responsive/`: Chứa các màn hình trung gian để tự động chuyển đổi giữa Mobile và Web tùy kích thước màn hình.
- `shared/`: Chứa các UI widget có thể dùng chung.

Khi một feature có giao diện khác nhau giữa mobile và web:
```text
ui/
├── mobile/
│   └── <feature>/
└── web/
    └── <feature>/
```

### 2. Quy tắc quan trọng
- **Không gộp UI mobile và web vào một file** chỉ để giảm số lượng file, nếu hai giao diện này có layout hoặc UX hoàn toàn khác nhau.
- UI khác nhau không có nghĩa là logic phải khác nhau. UI sẽ gọi đến một `Controller` chung nếu logic của tính năng đó trên Web và Mobile là giống nhau.

### 3. Form & Keyboard Navigation
Các giao diện (đặc biệt là Mobile) có nhiều input field mà user phải nhập đầy đủ trước khi submit **bắt buộc phải triển khai cơ chế điều hướng bằng bàn phím** (Next/Done/Enter) thông qua explicit `FocusNode` chain để tối ưu UX và đảm bảo độ chính xác.

Tuyệt đối **KHÔNG** sử dụng `FocusScope.of(context).nextFocus()` một cách mặc định. Việc này sẽ gây lỗi focus sai mục tiêu khi giao diện có các thành phần focusable phụ trợ (như con mắt ẩn/hiện mật khẩu, icon button, custom dropdown...).

- **Quản lý Submit Logic**:
  Để tránh duplicate code, tuyệt đối **không** tạo riêng một hàm submit cho bàn phím nếu nó chứa logic nghiệp vụ/validation. Hãy gọi trực tiếp phương thức của Controller bên trong `onSubmitted` hoặc tách logic ra một hàm `_submit()` duy nhất dùng chung cho cả Button và Keyboard.
  `FocusNode` chỉ chịu trách nhiệm quản lý UI focus, tuyệt đối không đưa state này vào Controller. Controller chỉ xử lý business logic (validation, loading, API).

- **Mobile Behavior**:
  Sử dụng explicit focus navigation cho Mobile.
  - Đối với các field trung gian: Cấu hình `textInputAction: TextInputAction.next` và gọi `_nextFieldFocusNode.requestFocus()` trong `onSubmitted` để trực tiếp chuyển đúng field cần thiết.
  - Đối với field cuối cùng: Cấu hình `textInputAction: TextInputAction.done` và gọi action gửi (ví dụ: `_controller.login(...)`) trong `onSubmitted`.

- **Web Behavior**:
  - Không được lạm dụng hành vi chuyển focus `requestFocus()` của Mobile lên cho Web nếu nó làm hỏng Tab order mặc định của accessibility. Hãy giữ nguyên `FocusNode` nhưng có thể không cần ép `requestFocus()` khi nhấn phím Enter trên field giữa.
  - Hành vi chuẩn khi nhấn phím `Enter` trên Web form là **Submit form**. Ở tất cả các field trên màn hình Web, cấu hình `onSubmitted` gọi đến logic submit để mô phỏng chính xác HTML form (ví dụ form Đăng nhập nhấn Enter ở field Email vẫn sẽ gọi hàm Login).

### 4. Image Rendering
Tuyệt đối **không** sử dụng trực tiếp các class như `Image.network`, `CircleAvatar(backgroundImage: ...)` hay viết lại các logic xử lý trạng thái loading/error/fallback của ảnh network rải rác khắp các file UI.

- Bắt buộc phải tái sử dụng component `AppNetworkImage` tại `lib/ui/shared/image/app_network_image.dart` cho mọi nhu cầu render ảnh từ internet.
- `AppNetworkImage` đã được cấu hình sẵn các rule:
  - Tự động fallback về icon/màu mặc định an toàn.
  - Xử lý trạng thái loading mượt mà bằng `CircularProgressIndicator`.
  - Có các param như `isCircle`, `borderRadius`, `width`, `height` để tự động render bo góc tương ứng.
  - Chèn header `User-Agent` mặc định để vượt qua các rào cản CDN (ví dụ như Cloudflare đối với api `ui-avatars.com`).
