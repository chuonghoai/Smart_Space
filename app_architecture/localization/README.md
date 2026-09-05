# Quy tắc Đa Ngôn Ngữ (Localization)

Đây là quy tắc **TUYỆT ĐỐI BẮT BUỘC**.

### 1. Không Hardcode UI Text
- Khi thêm text hiển thị trên UI, **không được hardcode** string (VD: `Text('Login')`).
- Phải sử dụng qua `AppLocalizations.of(context)!`.

### 2. File ngôn ngữ (ARB)
Mọi UI text mới phải được thêm vào cả 2 file:
- `lib/l10n/app_en.arb` (English)
- `lib/l10n/app_vi.arb` (Vietnamese)

Tuyệt đối không chỉ thêm text vào một ngôn ngữ mà bỏ qua ngôn ngữ còn lại.

### 3. Sinh code tự động
Sau khi chỉnh sửa/thêm text vào các file `.arb`, **BẮT BUỘC** phải chạy lệnh sau trên terminal:
```bash
flutter gen-l10n
```
Sau đó sử dụng generated code trong file UI của bạn.
