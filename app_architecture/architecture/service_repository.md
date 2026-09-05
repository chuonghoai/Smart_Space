# Service & Repository Layer

## Service Layer (`ReportService`, v.v)
- **Trách nhiệm:** Đóng gói (wrap) Repository. Có thể xử lý thêm các logic phối hợp nhiều repo hoặc format dữ liệu phụ.
- **Dependency:** Phụ thuộc vào `Repository`.
- **DO:** Trả về `ApiResponse<T>`.
- **DON'T:** KHÔNG được lưu trữ state (nên là class stateless).

## Repository Layer (`ReportRepo`, `ReportRepoApi`)
- **Trách nhiệm:** Giao tiếp trực tiếp với Data Source (API thông qua `ApiClient` hoặc Local Storage/Mock).
- **Dependency:** Phụ thuộc vào `ApiClient` (Network Layer).
- **DO:** Decode JSON thành Object bằng method `decoder`. Trả về `ApiResponse<T>`.
- **DON'T:** KHÔNG xử lý business logic, KHÔNG chứa UI logic.

**Lưu ý:** Việc sử dụng Interface (`ReportRepo`) và Implementation (`ReportRepoApi`, `ReportRepoMock`) giúp hỗ trợ môi trường Mock (qua biến `useMock`) rất tốt. Hãy tiếp tục duy trì pattern này.
