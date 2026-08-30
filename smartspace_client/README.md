# Cách dùng cơ chế go, push, pop, pushReplacement
 - Go: Thay thế widget hiện tại và xóa widget trước đó khỏi stack
 - Push: Push route mới lên stack, route hiện tại vẫn nằm bên dưới.
 - Pop: Pop route hiện tại, quay lại route trước.
 - pushReplacement: Push route mới và thay thế route hiện tại trong stack.

## 🌐 Ngôn ngữ (Localization)
 Để thêm ngôn ngữ mới, bạn cần thực hiện các bước sau:
 
 1. Tạo file arb mới cho ngôn ngữ mới: 
 ```bash
 flutter gen-l10n
 ```
 
 2. Sau khi tạo file arb mới, bạn cần chạy lại lệnh trên để cập nhật file app_localizations.dart: 
 

## 🌍 Cấu hình Môi trường (Environment Setup)

Dự án sử dụng file `.env` để quản lý các cấu hình kết nối API khi phát triển ở môi trường local (Development). 
Đảm bảo bạn có file `.env` ở thư mục gốc của dự án với nội dung mẫu:

```env
API_TIMEOUT = 10000
PORT = [Port của API backend local]
LAN_IP = [IP của máy tính đang chạy backend]
```

- **`PORT`**: Cổng của API backend local.
- **`LAN_IP`**: Địa chỉ IP mạng LAN của máy tính đang chạy backend (dùng khi test trên điện thoại thật). Mỗi thành viên trong nhóm cần tự đổi IP này cho đúng với IP máy tính cá nhân.

## 🚀 Hướng dẫn Chạy ứng dụng (Development)

Hệ thống sẽ **tự động** xác định nền tảng đang chạy và trỏ về đúng địa chỉ Backend.

### 1. Trên Web và Mobile Emulator/Simulator
Bạn chỉ cần chạy lệnh thông thường. Ứng dụng sẽ tự động trỏ về `localhost:<PORT>` (đối với Web, iOS Simulator) hoặc `10.0.2.2:<PORT>` (đối với Android Emulator).

```bash
flutter run
```

### 2. Trên Thiết bị vật lý (Physical Device)
Thiết bị thật (điện thoại cắm cáp USB hoặc qua Wi-Fi) không thể gọi `localhost`. Do đó bạn **bắt buộc** phải truyền cờ `IS_PHYSICAL=true` khi chạy app. Lúc này app sẽ tự động trỏ API về địa chỉ `LAN_IP` đã cấu hình trong file `.env`.

```bash
flutter run --dart-define=IS_PHYSICAL=true
```

### 3. Chạy trên thiết bị chỉ định
Chạy trên emulator:
```bash
flutter run -d emulator-5554
```

Chạy trên web:
```bash
flutter run -d edge
```

Lệnh xem các thiết bị có thể được chạy:
```bash
flutter devices
```

## 📦 Triển khai Môi trường Thật (Production)

Khi build ứng dụng để deploy lên môi trường Production (môi trường thật), chúng ta không dùng các IP local trong `.env` nữa. Bạn chỉ cần truyền trực tiếp URL API thực tế thông qua cờ `API_URL`.

**Lệnh Build Production:**

```bash
# Build Android APK
flutter build apk --dart-define=API_URL=https://api.your-domain.com

# Build iOS
flutter build ios --dart-define=API_URL=https://api.your-domain.com

# Build Web
flutter build web --dart-define=API_URL=https://api.your-domain.com
```

> **Lưu ý:** Bất cứ khi nào cờ `API_URL` được cung cấp, nó sẽ **ghi đè** toàn bộ logic nhận diện tự động ở môi trường Development.

## ⚠️ Lưu ý về Security (HTTP Cleartext)

Nếu API Backend ở local của bạn không chạy HTTPS mà chạy HTTP thuần, bạn sẽ bị lỗi không gọi được API trên Android 9+ và iOS vì lý do bảo mật.
Để test ở Development, bạn có thể cấp quyền tạm thời:

- **Android**: Thêm thuộc tính `android:usesCleartextTraffic="true"` vào thẻ `<application>` trong file `android/app/src/main/AndroidManifest.xml`.
- **iOS**: Thêm key `NSAppTransportSecurity` với dictionary con `NSAllowsArbitraryLoads: true` vào file `ios/Runner/Info.plist`.
