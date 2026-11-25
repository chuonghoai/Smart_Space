# Kiến trúc WebRTC Audio Call & Nhắn tin Admin – Client

## 1. Tổng quan

Tài liệu mô tả kiến trúc triển khai cho:
1. **Cuộc gọi thoại WebRTC (Audio-Only)** trên cả 3 ứng dụng (`smartspace_client`, `smartspace_staff`, `smartspace_admin`) thông qua `mobile_shared` và Backend `SmartSpace_Backend`, sử dụng **duy nhất WebSocket làm kênh Call Invitation và Signaling**.
2. **Mở hội thoại & nhắn tin Admin ↔ Client theo điều kiện xử lý lại phản ánh**, kèm **đính kèm nhiều phản ánh** trong một tin nhắn.

> **Ràng buộc nghiệp vụ**: Chỉ cho phép thực hiện cuộc gọi khi **cả hai bên đều đang mở ứng dụng hoặc chạy nền và còn duy trì kết nối WebSocket hợp lệ**. Hệ thống **không sử dụng FCM Call Push, PushKit/CallKit hay Android Full-Screen Intent** để đánh thức ứng dụng đã tắt (terminated).

---

## 2. Ma trận phân quyền hợp nhất (`CommunicationPermissionService`)

Nguồn kiểm tra duy nhất tại Backend: `com.vn.smart_space.service.communication.CommunicationPermissionService` được dùng chung bởi:
- `ConversationService` (`createConversation`, `checkCommunicationEligibility`, `getConversationDetail`, `getConversationInfo`)
- `ChatMessageService` (`sendMessage`)
- `CallService` (`initiateCall`, `acceptCall`, `acknowledgeRinging`, `relaySignal`)

| Quan hệ | Nhắn tin / Mở hội thoại | Gọi miễn phí (WebRTC) | Gọi thường (`tel:`) | Ghi chú |
|---|---|---|---|---|
| **Client ↔ Client** | Không | Không | Không | Từ chối hoàn toàn ở Backend & UI |
| **Client ↔ Staff** | Có điều kiện | Có điều kiện (cùng rule khóa/mở hội thoại) | Chỉ khi không ẩn danh & có SĐT | Anonymous (`isAnonymous = true`): **vẫn cho phép Gọi miễn phí (ẩn danh)**, tắt `tel:` |
| **Staff ↔ Staff** | Cho phép | Cho phép | Nếu có SĐT | Không phụ thuộc Report |
| **Staff ↔ Admin** | Cho phép | Cho phép | Nếu có SĐT | Không phụ thuộc Report |
| **Admin ↔ Client** | Chỉ khi Client có ít nhất 1 Report `isReviewResolved == false && status == PROCESSING` | Khớp hoàn toàn với quyền mở/gửi tin nhắn | Chỉ khi không ẩn danh & có SĐT | Anonymous (`isAnonymous = true`): tách context riêng bằng prefix `admin_anon_` vs `admin_user_` |

---

## 3. Kiểm tra trạng thái WebSocket & Heartbeat (`WebSocketSessionRegistry`)

Backend xác minh kết nối sống trực tiếp qua `WebSocketSessionRegistry` (không dựa vào DB/FCM token):

- Lưu thông tin từng STOMP session đã xác thực JWT: `sessionId`, `userId`, `deviceId`, `connectedAt`, `lastHeartbeatAt`, `tokenExpiresAt`, `authenticated`, `subscribedToCallQueue`.
- **Heartbeat & Timeout**:
  - Client và Spring SimpleBroker bật STOMP heartbeat `10s / 10s`, đồng thời app gửi keepalive `/smartspace/call.ping` mỗi `15s`.
  - Session quá `webrtc.ws.heartbeat-timeout-seconds` (mặc định `35s`) không có frame/heartbeat, token hết hạn, hoặc biến mất khỏi `SimpUserRegistry` sẽ bị `evictStaleSessions()` loại bỏ ngay.
- **Đa thiết bị (`Multi-device`)**:
  - `CALL_INCOMING` đẩy qua `/user/queue/call` tới các phiên WebSocket hợp lệ của người nhận, dùng chung **một `CallSession` duy nhất**.
  - Chỉ thiết bị đầu tiên Accept thành công (`acceptedDeviceId == null`); Backend gửi `CALL_HANDLED_ELSEWHERE` qua WebSocket để tự đóng giao diện cuộc gọi đến trên các thiết bị còn lại.
  - Nếu một thiết bị ngắt WebSocket nhưng thiết bị khác vẫn còn kết nối hợp lệ, cuộc gọi đang đổ chuông vẫn giữ cho đến khi tất cả kết nối WebSocket hợp lệ của người nhận đều mất (hoặc thiết bị đã Accept ngắt kết nối).

---

## 4. Vòng đời cuộc gọi & Kênh Signaling WebSocket

### 4.1. State Machine (`ECallStatus` / `CallStatus`)

```
CONNECTING ──(Receiver xác nhận qua WS/Notification nội bộ)──> RINGING
    │                                                             │
    ├── FAILED ("Không thể kết nối") nếu:                        ├── REJECTED (Receiver từ chối)
    │    • Caller/Receiver không có WS hợp lệ                     ├── CANCELLED (Caller hủy)
    │    • Hết 10s connecting-timeout chưa ACK                    ├── MISSED (Hết 45s timeout)
    │    • WS mất kết nối trong lúc CONNECTING                    ├── FAILED (WS mất kết nối khi đang đổ chuông)
    │                                                             └── ACCEPTED (Receiver ấn Trả lời)
    │                                                                    │
    │                                           (WebRTC PeerConnection Connected thực sự)
    │                                                                    ▼
    │                                                                 ONGOING ──> ENDED / FAILED
```

- **Người nhận đã tắt ứng dụng (Terminated) / mất mạng**: Backend phát hiện `!wsSessionRegistry.hasValidCallConnection(receiverId)` trong `initiateCall`, từ chối ngay (`call.cannot_connect`, không tạo `CallSession`, không chuyển `ringing`, không gửi FCM). Phía người gọi hiển thị `"Không thể kết nối"` và tự giải phóng.
- **Ứng dụng người nhận đang chạy nền (Background) còn WebSocket**: App vẫn giữ `CallController` sống nhờ WebSocket, hiển thị thông báo chuẩn (`showActiveWsCallNotice`, **không** `fullScreenIntent`, **không** đánh thức app đã kill) và đồng bộ trạng thái ngay khi quay lại foreground.

### 4.2. Kênh Signaling (WebSocket STOMP + REST nội bộ)

- **STOMP WebSocket (duy nhất cho Call Invitation & Signaling)**:
  - Client gửi: `/smartspace/call.ping`, `/smartspace/call.ringing`, `/smartspace/call.accept`, `/smartspace/call.reject`, `/smartspace/call.cancel`, `/smartspace/call.end`, `/smartspace/call.connected`, `/smartspace/call.signal`.
  - Server gửi riêng từng user: `/user/queue/call`.
- **REST API**: `GET /calls/ice-servers`, `GET /calls/permission`, `POST /calls`, `POST /calls/{callId}/{ringing|accept|reject|cancel|end|connected|signal}`, `GET /calls/{callId}`.
- **Firebase Cloud Messaging (FCM)**: Chỉ giữ lại cho **thông báo hệ thống thông thường** (Report, Chat, Tin tức, Khóa tài khoản); đã gỡ hoàn toàn mọi call push/wakeup.

---

## 5. STUN / TURN & Triển khai Production

Cấu hình động từ Backend qua biến môi trường (`.env.example`), trả về qua `/calls/ice-servers` và `CallSessionResponse` — **không hardcode credential TURN trong mã nguồn Flutter**.

| `WEBRTC_TURN_MODE` | Mô tả | Yêu cầu triển khai |
|---|---|---|
| `stun_only` (mặc định dev) | Chỉ dùng STUN (LAN / NAT nhẹ) | Không cần TURN server; có thể lỗi qua 4G/CGNAT |
| `coturn_hmac` (khuyến nghị self-host) | Sinh credential tạm thời chuẩn HMAC-SHA1 RFC 5766 | Chạy `docker-compose.coturn.yml`, mở UDP/TCP 3478 & relay UDP |
| `cloudflare` | Lấy short-lived TURN token từ Cloudflare Calls API | Cấu hình `WEBRTC_CF_TURN_TOKEN_ID` & `WEBRTC_CF_TURN_API_TOKEN` |
| `static_env` | Dùng TURN credential từ env Backend | Cấu hình `WEBRTC_TURN_URLS`, `WEBRTC_TURN_USERNAME`, `WEBRTC_TURN_CREDENTIAL` |

---

## 6. Admin ↔ Client Re-handling & Đính kèm nhiều phản ánh

- **Database**: `call_sessions`, `chat_message_reports` ([V20261125_call_sessions_and_message_reports.sql](sql/V20261125_call_sessions_and_message_reports.sql)).
- **UI**: `LinkedReportPickerSheet.showMulti`, `SelectedReportsPreviewBar`, `ChatMessageBubble` hiển thị text tuỳ chọn tách biệt phía trên từng card phản ánh.
