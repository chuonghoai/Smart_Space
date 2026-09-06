# Push Notification Architecture Rules (WebSocket & FCM)

Khi triển khai tính năng push notification (cả qua WebSocket và Firebase Cloud Messaging), tuyệt đối tuân thủ các quy tắc sau để đảm bảo Clean Architecture và SOLID:

## 1. Action Data Format
Backend phải luôn push notification payload theo một chuẩn `Action Data` chung, áp dụng cho cả WebSocket và FCM.
Payload phải chứa `type` (Action Type) và `payload` (Data).

**Ví dụ:**
```json
{
  "type": "REPORT_DETAIL",
  "payload": {
    "reportId": "12345-abcde"
  }
}
```

## 2. Notification Action Router (Client)
Tất cả các logic routing hoặc xử lý khi user tap vào notification (từ FCM system tray hoặc In-App Toast) đều phải đi qua `NotificationRouter`.

- **KHÔNG hardcode** việc check ID (`if (reportId != null)`) trong các file Infrastructure (như `AppServicesInitializer`, `NotificationProvider`, `FirebaseService`).
- Khi Infrastructure nhận được raw JSON data từ event, nó phải map về đối tượng `NotificationAction` và chuyển tiếp cho `NotificationRouter.handleAction(action)`.
- `NotificationRouter` sẽ dùng switch-case hoặc strategy pattern trên `action.type` để quyết định điều hướng thông qua GoRouter.

## 3. Separation of Concerns (WebSocket)
- Việc lắng nghe WebSocket (`webSocketService.subscribe`) cho notification hệ thống phải đặt ở một file service riêng biệt (vd: `NotificationWsService`).
- **KHÔNG** đặt logic setup WebSocket vào bên trong các StateNotifier/Provider chuyên quản lý state (như UnreadCount Provider). Các StateNotifier này chỉ nên hứng callback (vd: `onNotificationReceived`) để trigger gọi lại API đếm số lượng.

## 4. Trách Nhiệm Của Infrastructure layer
Các file khởi tạo app như `AppServicesInitializer`:
- Chỉ chịu trách nhiệm khởi tạo `NotificationWsService` hoặc lắng nghe tap event từ `FirebaseService`.
- Khi có event, gọi đến `NotificationRouter`.
- **Tuyệt đối KHÔNG** import các đường dẫn Router path trực tiếp để điều hướng màn hình.
