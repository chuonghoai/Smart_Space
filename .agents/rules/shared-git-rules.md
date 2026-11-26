# Shared Git Rules

Mọi thao tác liên quan đến Git của Agent phải tuân thủ các quy định sau:

1. **Luôn kiểm tra trạng thái trước khi thao tác:**
   Sử dụng các lệnh:
   - `git status`
   - `git branch --show-current`
   - `git diff`
   - `git log`

2. **Các hành động bị NGHIÊM CẤM (trừ khi có sự cho phép rõ ràng từ user):**
   - KHÔNG force push.
   - KHÔNG `git reset --hard` gây mất code khi chưa được xác nhận.
   - KHÔNG `checkout` làm mất các thay đổi chưa được commit (uncommitted changes).
   - KHÔNG xóa branch khác branch đang thao tác hoặc review.
   - KHÔNG commit các file không liên quan đến scope của task.
   - KHÔNG merge Pull Request / branch khi chưa được user phê duyệt (approve).
   - KHÔNG xóa branch trước khi merge thành công.

3. **Cẩn trọng khi thay đổi remote:**
   - Trước các thao tác có khả năng thay đổi remote repository, phải kiểm tra trạng thái và đảm bảo đang thao tác trên đúng branch.
