# Map Feature – API Usage by Role

## 1. Client (`smartspace_client`)

| Chức năng | Method | Endpoint | Mô tả |
|-----------|--------|----------|-------|
| Lấy reports trong viewport | `GET` | `/reports/map?min_lat=&max_lat=&min_lng=&max_lng=&limit=300` | Trả về danh sách report trong bounding box, hỗ trợ truncation khi vượt limit |

**Frontend call**: `ReportRepoApi.getReportsInBounds()` → `GET /reports/map`

## 2. Staff (`smartspace_staff`)

| Chức năng | Method | Endpoint | Mô tả |
|-----------|--------|----------|-------|
| Lấy reports được gán | `GET` | `/reports/staff/assigned?status=all&page=0&limit=10` | Staff **không gọi API map riêng**. Map screen dùng lại dữ liệu `assignedReports` đã fetch từ Home |

**Frontend call**: `MapController.getFilteredReports(homeState)` — lọc từ `homeState.assignedReports` (đã fetch qua `GET /reports/staff/assigned`). **Không có API `/map` riêng cho staff.**

## 3. Admin (`smartspace_admin`)

| Chức năng | Method | Endpoint | Mô tả |
|-----------|--------|----------|-------|
| Lấy reports cho map | `GET` | `/admin/reports/map?status=&severity=&assigneeId=&from=&to=&limit=500` | Lọc theo status, severity, assignee, khoảng thời gian. Yêu cầu role `admin` |

**Frontend call**: `MapRepository.getMapReports()` → `GET /admin/reports/map`

---

## Tóm tắt

| Role | API endpoint | Viewport-based? | Filter hỗ trợ |
|------|-------------|-----------------|----------------|
| **Client** | `GET /reports/map` | ✅ (bounding box) | Chỉ bounds + limit |
| **Staff** | `GET /reports/staff/assigned` (reuse) | ❌ | status, page, limit |
| **Admin** | `GET /admin/reports/map` | ❌ | status, severity, assigneeId, from, to, limit |





Staff hoàn tất có note và ảnh → client thấy thẻ trong popup và ở màn chi tiết, cả sau khi đánh giá tốt.
Đánh giá xấu → hiện cả thẻ kết quả lẫn khối "chưa giải quyết".
Staff xử lý lại → trong lúc processing thẻ bị ẩn. Sau khi hoàn tất lần 2 mà không nhập note, note cũ không còn hiện.
Staff hoàn tất không có note và ảnh → không hiện thẻ rỗng.