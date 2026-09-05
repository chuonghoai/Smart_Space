# Quy tắc Controller Layer

Controller đóng vai trò làm cầu nối giữa UI và business logic (Service).

### Trách nhiệm của Controller:
- Nhận input/action từ UI.
- Quản lý UI state cần thiết.
- Quản lý các trạng thái như `isLoading`, `error`, `success`.
- Điều phối flow giữa UI và Service.
- Gọi Service để thực hiện nghiệp vụ.
- Xử lý kết quả trả về từ Service để cập nhật state hoặc quyết định UI flow.
- Thực hiện navigation (sử dụng GoRouter) khi điều hướng là một phần của UI/application flow.
- **Controller có thể quản lý hoặc triển khai animation logic của UI** khi animation cần được điều phối cùng với UI state hoặc interaction flow. Việc đặt animation logic trong Controller phải hợp lý với context của tính năng và không biến Controller thành nơi chứa toàn bộ presentation code.

### Controller KHÔNG NÊN:
- Trực tiếp thực hiện HTTP/API request (đây là nhiệm vụ của Repository/Service).
- Chứa code truy cập database/data source trực tiếp.
- Duplicate business logic đã có trong Service.
- Tách riêng Controller cho Mobile và Web nếu logic nghiệp vụ của 2 nền tảng là hoàn toàn giống nhau (Sử dụng Controller dùng chung).
