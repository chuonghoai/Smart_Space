# Quy tắc Model Layer

Model chịu trách nhiệm định nghĩa cấu trúc dữ liệu của ứng dụng.

### Trách nhiệm của Model:
- Định nghĩa Request model, Response model.
- Định nghĩa Entity / Model đại diện cho domain.
- Chứa các `enum` liên quan đến domain/feature.

### Quy tắc quan trọng:
- **Bắt buộc tái sử dụng Model** nếu một model tương tự hoặc giống hệt đã tồn tại.
- KHÔNG tạo duplicate model chỉ vì một UI mới cần cùng dữ liệu. Hãy tham chiếu đến model đã có sẵn trong project.
