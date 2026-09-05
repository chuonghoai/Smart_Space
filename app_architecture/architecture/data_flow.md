# Data Flow & State Management

Ứng dụng `smartspace_client` sử dụng **Riverpod** làm giải pháp quản lý trạng thái. Data Flow tuân thủ luồng một chiều (Unidirectional Data Flow).

## Sơ đồ luồng dữ liệu

```mermaid
sequenceDiagram
    participant U as UI (Screen/Widget)
    participant C as UI Controller (StateNotifier)
    participant P as Feature Provider (StateNotifier)
    participant S as Feature Service
    participant R as Repository
    participant A as API Client

    U->>C: Hành động người dùng (Ví dụ: Nhấn "Làm mới")
    C->>P: Gọi hàm thao tác dữ liệu (Ví dụ: fetchReports())
    P->>P: Cập nhật State (isLoading = true)
    P->>S: Yêu cầu lấy dữ liệu (getDangerousReports())
    S->>R: Gọi Repository logic
    R->>A: Gửi HTTP Request tới Backend
    A-->>R: Trả về JSON Data
    R-->>S: Trả về ApiResponse<T>
    S-->>P: Trả về kết quả
    P->>P: Cập nhật State (isLoading = false, data = reports)
    P-->>C: State thay đổi (Lắng nghe qua ref.listen/ref.watch)
    C-->>U: UI render lại với dữ liệu mới
```

## Giải thích luồng
1. **User Action:** Bắt đầu từ UI khi người dùng tương tác.
2. **Controller/Provider:** Các action không liên quan logic chia sẻ (vd: mở/đóng tab) được xử lý tại UI Controller. Các action lấy/sửa dữ liệu được truyền tới Feature Provider.
3. **Fetching Data:** Provider không gọi API trực tiếp. Nó nhờ Service.
4. **Service & Repository:** Service có thể kết hợp nhiều Repository hoặc thêm bước log, sau đó Repository thực thi API call.
5. **State Update:** Khi có dữ liệu, Provider emit state mới. UI đang `ref.watch(provider)` sẽ tự động rebuild.
