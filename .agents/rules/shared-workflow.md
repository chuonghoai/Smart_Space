# Shared Workflow Rules

Mọi Skill của AI Agent đều phải tuân thủ quy trình chung (Shared Workflow) sau đây.
Không được nhảy thẳng vào viết code hoặc thực hiện thay đổi khi chưa hoàn thành các bước hiểu và phân tích.

## Quy trình chuẩn (Standard Workflow)

1. **Understand (Hiểu yêu cầu)**
   - Đọc kỹ yêu cầu của user.
   - Xác định rõ mục tiêu, phạm vi thay đổi.
2. **Inspect Repository (Kiểm tra kho lưu trữ)**
   - Kiểm tra cấu trúc hiện tại của repo, các file liên quan.
3. **Inspect Architecture (Kiểm tra kiến trúc)**
   - Đọc các tài liệu kiến trúc: `app_architecture/`, `backend_architecture/`.
   - Đọc tài liệu UI/UX & L10n: `app_architecture/design/design.md` và `shared-ui-l10n-rules.md` (nếu có thay đổi UI/text).
4. **Inspect Existing Implementation (Kiểm tra mã nguồn hiện tại)**
   - Tìm các module/feature liên quan.
   - Đánh giá khả năng tái sử dụng (không tạo code mới nếu có thể dùng lại).
5. **Inspect Related Git History (Kiểm tra lịch sử Git)**
   - Xem các commit gần đây về tính năng tương tự để hiểu pattern hiện tại, convention, và các bug fix trước đó.
6. **Analyze (Phân tích)**
   - Phân tích rủi ro, side effects, dependency.
7. **Implementation / Review Plan (Lập kế hoạch)**
   - Tạo kế hoạch rõ ràng cho các thay đổi cần thiết.
8. **Execute only when authorized (Thực thi khi được phép)**
   - Chờ xác nhận của user với những thay đổi lớn hoặc khi Skill quy định rõ phải chờ.
9. **Validate (Xác minh)**
   - Kiểm tra lại kết quả thay đổi.
10. **Report (Báo cáo)**
    - Thông báo cho user kết quả công việc.
