-- --------------------------------------------------------
-- Tệp dữ liệu mẫu (Seed Data) cho SmartSpace_Backend
-- Đảm bảo bạn đã chạy Hibernate để tạo cấu trúc bảng trước khi import file này, hoặc các table đã tồn tại
-- --------------------------------------------------------

-- Lưu ý: Mật khẩu của các user được mã hoá Bcrypt là 'Ad123456!'
-- Danh sách tài khoản đăng nhập mẫu:
-- 1/ Admin: admin@gmail.com (u1) | cudan2@gmail.com (u4) | Mật khẩu: Ad123456!
-- 2/ Staff: staff1@gmail.com (u5) | staff2@gmail.com (u6) | staff3@gmail.com (u8) | staff4@gmail.com (u9) | staff5@gmail.com (u10) | Mật khẩu: Ad123456!
-- 3/ Client: user@gmail.com (u2) | cudan@gmail.com (u3) | client3@gmail.com (u7) | Mật khẩu: Ad123456!
-- 4/ Nhờ làm giùm: xem kịch bản test ở mục "Nhờ làm giùm" cuối file (staff1 = người nhờ, staff2 = người làm giùm)

SET FOREIGN_KEY_CHECKS = 0;

-- --------------------------------------------------------
-- Xóa toàn bộ dữ liệu cũ theo thứ tự ngược của Foreign Keys
-- --------------------------------------------------------
DELETE FROM message_media;
DELETE FROM chat_messages;
DELETE FROM conversation_participants;
DELETE FROM conversations;
DELETE FROM device_tokens;
DELETE FROM user_notification_states;
DELETE FROM notifications;
DELETE FROM activity_histories;
-- Ví & nhờ làm giùm (reset để số dư khớp lịch sử giao dịch seed bên dưới; giữ nguyên wallet_configs của admin)
DELETE FROM staff_wallet_transactions;
DELETE FROM staff_withdrawal_requests;
DELETE FROM report_delegations;
DELETE FROM staff_wallets;
DELETE FROM reports;
DELETE FROM users;
DELETE FROM positions;

-- --------------------------------------------------------
-- Table: positions (Chức vụ)
-- Phụ thuộc: (Không)
-- Model: Position (AbstractEntity)
-- Columns: id, created_at, updated_at, code, name, description, is_active
-- Test: p5 ngừng hoạt động (không hiện ở dropdown gán/lọc), p4 chưa có staff (thử xóa được)
-- --------------------------------------------------------
INSERT INTO positions (id, created_at, updated_at, code, name, description, is_active) VALUES
('p1', NOW(), NOW(), 'ELECTRICIAN', 'Kỹ thuật điện', 'Xử lý sự cố điện, đèn đường, dây điện', TRUE),
('p2', NOW(), NOW(), 'PLUMBER', 'Kỹ thuật cấp thoát nước', 'Xử lý ống nước vỡ, ngập úng, rò rỉ', TRUE),
('p3', NOW(), NOW(), 'SANITATION', 'Vệ sinh môi trường', 'Thu gom rác, xử lý ô nhiễm, vệ sinh khu vực công cộng', TRUE),
('p4', NOW(), NOW(), 'SECURITY', 'An ninh trật tự', 'Xử lý tai nạn, cháy nổ, mất an ninh', TRUE),
('p5', NOW(), NOW(), 'CONSTRUCTION', 'Xây dựng - Hạ tầng (cũ)', 'Chức vụ đã ngừng hoạt động', FALSE);

-- --------------------------------------------------------
-- Table: users
-- Phụ thuộc: (Không)
-- Model: User (AbstractEntity)
-- Columns: id, created_at, updated_at, full_name, date_of_birth, phone, email, password, gender, role, status, avatar_url, language
-- --------------------------------------------------------
INSERT INTO users (id, created_at, updated_at, full_name, date_of_birth, phone, email, password, gender, role, status, avatar_url, language) VALUES
('u1', NOW(), NOW(), 'Nguyễn Quản Trị', '1988-03-12', '0909000001', 'admin@gmail.com', '$2a$10$nosRTfjEU6rYa5Ps58DdEuEnns.WJrUKgAWR56/lpphULiTLUrJqy', 'male', 'admin', 'active', 'https://ui-avatars.com/api/?name=Nguyen+Quan+Tri&background=00796B&color=fff&size=200&bold=true', 'vi'),
('u4', NOW(), NOW(), 'Cư Dân 2 (Admin)', '1990-01-01', '0901234567', 'cudan2@gmail.com', '$2a$10$nosRTfjEU6rYa5Ps58DdEuEnns.WJrUKgAWR56/lpphULiTLUrJqy', 'male', 'admin', 'active', 'https://ui-avatars.com/api/?name=AD&background=6366f1&color=fff&size=200&bold=true&font-size=0.4', 'vi'),
('u5', NOW(), NOW(), 'Nguyễn Văn Nhân Viên', '1993-08-21', '0934567890', 'staff1@gmail.com', '$2a$10$nosRTfjEU6rYa5Ps58DdEuEnns.WJrUKgAWR56/lpphULiTLUrJqy', 'male', 'staff', 'active', 'https://ui-avatars.com/api/?name=Nguyen+Van+Staff&background=0284c7&color=fff&size=200&bold=true', 'vi'),
('u6', NOW(), NOW(), 'Lê Thị Hỗ Trợ', '1996-11-05', '0945678901', 'staff2@gmail.com', '$2a$10$nosRTfjEU6rYa5Ps58DdEuEnns.WJrUKgAWR56/lpphULiTLUrJqy', 'female', 'staff', 'active', 'https://ui-avatars.com/api/?name=Le+Thi+Staff&background=0284c7&color=fff&size=200&bold=true', 'vi'),
('u2', NOW(), NOW(), 'Trần Thị User', '1995-05-15', '0912345678', 'user@gmail.com', '$2a$10$nosRTfjEU6rYa5Ps58DdEuEnns.WJrUKgAWR56/lpphULiTLUrJqy', 'female', 'client', 'active', 'https://ui-avatars.com/api/?name=Tran+Thi+User&background=6366f1&color=fff&size=200&bold=true&font-size=0.4', 'vi'),
('u3', NOW(), NOW(), 'Lê Hữu Cư Dân', '1992-10-20', '0923456789', 'cudan@gmail.com', '$2a$10$nosRTfjEU6rYa5Ps58DdEuEnns.WJrUKgAWR56/lpphULiTLUrJqy', 'male', 'client', 'active', 'https://ui-avatars.com/api/?name=Le+Huu+Cu+Dan&background=8b5cf6&color=fff&size=200&bold=true&font-size=0.4', 'vi'),
('u7', NOW(), NOW(), 'Phạm Minh Khách Hàng', '1998-02-14', '0967890123', 'client3@gmail.com', '$2a$10$nosRTfjEU6rYa5Ps58DdEuEnns.WJrUKgAWR56/lpphULiTLUrJqy', 'male', 'client', 'active', 'https://ui-avatars.com/api/?name=Pham+Minh+Client&background=10b981&color=fff&size=200&bold=true', 'vi');

-- Staff bổ sung để test chức vụ (u9 chưa có chức vụ, u10 bị khóa)
INSERT INTO users (id, created_at, updated_at, full_name, date_of_birth, phone, email, password, gender, role, status, avatar_url, language) VALUES
('u8', NOW(), NOW(), 'Trần Văn Điện', '1991-04-18', '0956789012', 'staff3@gmail.com', '$2a$10$nosRTfjEU6rYa5Ps58DdEuEnns.WJrUKgAWR56/lpphULiTLUrJqy', 'male', 'staff', 'active', 'https://ui-avatars.com/api/?name=Tran+Van+Dien&background=0284c7&color=fff&size=200&bold=true', 'vi'),
('u9', NOW(), NOW(), 'Võ Thị Môi Trường', '1994-12-02', '0978901234', 'staff4@gmail.com', '$2a$10$nosRTfjEU6rYa5Ps58DdEuEnns.WJrUKgAWR56/lpphULiTLUrJqy', 'female', 'staff', 'active', 'https://ui-avatars.com/api/?name=Vo+Thi+Moi+Truong&background=0284c7&color=fff&size=200&bold=true', 'vi'),
('u10', NOW(), NOW(), 'Đặng Minh Bảo Vệ', '1989-09-09', '0989012345', 'staff5@gmail.com', '$2a$10$nosRTfjEU6rYa5Ps58DdEuEnns.WJrUKgAWR56/lpphULiTLUrJqy', 'male', 'staff', 'blocked', 'https://ui-avatars.com/api/?name=Dang+Minh+Bao+Ve&background=0284c7&color=fff&size=200&bold=true', 'vi');

-- Gán chức vụ cho staff (cột users.position_id, FK -> positions.id)
UPDATE users SET position_id = 'p2' WHERE id = 'u5';
UPDATE users SET position_id = 'p3' WHERE id = 'u6';
UPDATE users SET position_id = 'p1' WHERE id = 'u8';
UPDATE users SET position_id = 'p4' WHERE id = 'u10';

-- --------------------------------------------------------
-- Table: reports
-- Phụ thuộc: users
-- Model: Report (AbstractEntity)
-- Columns: id, created_at, updated_at, title, description, image_url, latitude, longitude, severity, status, user_id, assigned_staff_id, image_urls, address, location_description, is_anonymous
-- --------------------------------------------------------
INSERT INTO reports (id, created_at, updated_at, title, description, image_url, latitude, longitude, severity, status, user_id, assigned_staff_id, image_urls, address, location_description, is_anonymous) VALUES
('r1', DATE_SUB(NOW(), INTERVAL 15 MINUTE), DATE_SUB(NOW(), INTERVAL 15 MINUTE), 'Đèn đường hỏng', 'Cột đèn số 12 bị hỏng không sáng vào ban đêm', 'https://picsum.photos/400/300?random=1', 10.762622, 106.660172, 'low', 'pending', 'u2', 'u5', 'https://picsum.photos/400/300?random=1', 'Quận 10, TP.HCM', 'Gần ngã tư', FALSE),
('r2', DATE_SUB(NOW(), INTERVAL 45 MINUTE), DATE_SUB(NOW(), INTERVAL 10 MINUTE), 'Rác thải đổ bừa bãi', 'Khu vực công viên có người đổ rác bừa bãi gây bốc mùi', 'https://picsum.photos/400/300?random=2', 10.763622, 106.661172, 'medium', 'processing', 'u3', 'u5', 'https://picsum.photos/400/300?random=2', 'Quận 10, TP.HCM', 'Cạnh công viên', FALSE),
('r3', DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_SUB(NOW(), INTERVAL 1 HOUR), 'Tai nạn giao thông', 'Tai nạn ở ngã tư, cần hỗ trợ khẩn cấp', 'https://picsum.photos/400/300?random=3', 10.764622, 106.662172, 'critical', 'pending', 'u2', 'u5', 'https://picsum.photos/400/300?random=3', 'Quận 10, TP.HCM', 'Ngã tư đường', TRUE),
('r4', DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'Đường ống nước vỡ', 'Nước ngập tràn ra đường hẻm 45', 'https://picsum.photos/400/300?random=4', 10.765622, 106.663172, 'high', 'processed', 'u3', 'u6', 'https://picsum.photos/400/300?random=4', 'Quận 10, TP.HCM', 'Hẻm 45', FALSE),
('r5', DATE_SUB(NOW(), INTERVAL 3 HOUR), DATE_SUB(NOW(), INTERVAL 3 HOUR), 'Cháy nhỏ tại kho hàng', 'Phát hiện khói bốc lên từ kho hàng bỏ hoang, cần PCCC', 'https://picsum.photos/400/300?random=5', 10.7769, 106.7009, 'critical', 'pending', 'u7', NULL, 'https://picsum.photos/400/300?random=5', 'Quận 1, TP.HCM', 'Kho hàng cũ', TRUE),
('r6', DATE_SUB(NOW(), INTERVAL 4 HOUR), DATE_SUB(NOW(), INTERVAL 1 HOUR), 'Hố tử thần trên đường', 'Hố sâu 50cm xuất hiện giữa đường Nguyễn Hữu Cảnh, nguy hiểm cho xe máy', 'https://picsum.photos/400/300?random=6', 10.7915, 106.7220, 'high', 'processing', 'u3', 'u5', 'https://picsum.photos/400/300?random=6', 'Bình Thạnh, TP.HCM', 'Giao lộ', FALSE),
('r7', DATE_SUB(NOW(), INTERVAL 5 HOUR), DATE_SUB(NOW(), INTERVAL 5 HOUR), 'Cây đổ chắn đường', 'Cây lớn bật gốc sau mưa, chắn hết làn xe tại Q7', 'https://picsum.photos/400/300?random=7', 10.7340, 106.7218, 'high', 'pending', 'u2', NULL, 'https://picsum.photos/400/300?random=7', 'Quận 7, TP.HCM', 'Đường lớn', FALSE),
('r8', DATE_SUB(NOW(), INTERVAL 6 HOUR), DATE_SUB(NOW(), INTERVAL 2 HOUR), 'Ngập nước kéo dài', 'Đường Tô Ngọc Vân ngập sâu 40cm, xe không lưu thông được', 'https://picsum.photos/400/300?random=8', 10.8488, 106.7590, 'medium', 'processing', 'u7', 'u6', 'https://picsum.photos/400/300?random=8', 'Thủ Đức, TP.HCM', 'Đoạn trũng', TRUE),
('r9', DATE_SUB(NOW(), INTERVAL 7 HOUR), DATE_SUB(NOW(), INTERVAL 3 HOUR), 'Tiếng ồn công trình', 'Công trường thi công gây ồn quá mức cho phép vào ban đêm', 'https://picsum.photos/400/300?random=9', 10.8015, 106.6527, 'low', 'processed', 'u2', 'u5', 'https://picsum.photos/400/300?random=9', 'Tân Bình, TP.HCM', 'Khu dân cư', FALSE),
('r10', DATE_SUB(NOW(), INTERVAL 8 HOUR), DATE_SUB(NOW(), INTERVAL 8 HOUR), 'Rò rỉ khí gas', 'Phát hiện mùi gas rò rỉ tại tòa nhà dân cư Q.Gò Vấp', 'https://picsum.photos/400/300?random=10', 10.8386, 106.6652, 'critical', 'pending', 'u3', NULL, 'https://picsum.photos/400/300?random=10', 'Gò Vấp, TP.HCM', 'Chung cư', TRUE),
('r11', DATE_SUB(NOW(), INTERVAL 9 HOUR), DATE_SUB(NOW(), INTERVAL 9 HOUR), 'Vỉa hè bị lấn chiếm', 'Hàng quán chiếm hết vỉa hè, người đi bộ phải đi dưới lòng đường', 'https://picsum.photos/400/300?random=11', 10.7724, 106.6681, 'low', 'rejected', 'u2', 'u5', 'https://picsum.photos/400/300?random=11', 'Quận 3, TP.HCM', 'Gần trường học', FALSE),
('r20', DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), 'Mất nắp cống (Tuần này)', 'Nguy hiểm cho người đi bộ', 'https://picsum.photos/400/300?random=12', 10.7724, 106.6681, 'high', 'processing', 'u2', 'u5', 'https://picsum.photos/400/300?random=12', 'Quận 1, TP.HCM', 'Trên vỉa hè', FALSE),
('r21', DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY), 'Đổ rác trộm (Cũ hơn)', 'Người dân đổ rác bừa bãi', 'https://picsum.photos/400/300?random=13', 10.7724, 106.6681, 'medium', 'processed', 'u2', 'u6', 'https://picsum.photos/400/300?random=13', 'Quận 10, TP.HCM', 'Bãi đất trống', FALSE),
('r12', DATE_SUB(NOW(), INTERVAL 10 HOUR), DATE_SUB(NOW(), INTERVAL 4 HOUR), 'Đường dây điện đứt', 'Dây điện trung thế bị đứt rơi xuống đường tại Q10', 'https://picsum.photos/400/300?random=12', 10.7726, 106.6690, 'critical', 'processing', 'u3', 'u5', 'https://picsum.photos/400/300?random=12', 'Quận 10, TP.HCM', 'Ngã tư', TRUE),
('r13', DATE_SUB(NOW(), INTERVAL 11 HOUR), DATE_SUB(NOW(), INTERVAL 5 HOUR), 'Ô nhiễm kênh rạch', 'Nước kênh đen bốc mùi hôi thối tại Phú Nhuận', 'https://picsum.photos/400/300?random=13', 10.7990, 106.6830, 'medium', 'processed', 'u2', 'u6', 'https://picsum.photos/400/300?random=13', 'Phú Nhuận, TP.HCM', 'Dọc bờ kênh', FALSE),
('r14', DATE_SUB(NOW(), INTERVAL 12 HOUR), DATE_SUB(NOW(), INTERVAL 12 HOUR), 'Sạt lở bờ sông', 'Bờ sông Sài Gòn sạt lở nghiêm trọng, đe dọa nhà dân Q2', 'https://picsum.photos/400/300?random=14', 10.7870, 106.7450, 'high', 'pending', 'u7', NULL, 'https://picsum.photos/400/300?random=14', 'Quận 2, TP.HCM', 'Khu dân cư', FALSE),
('r15', DATE_SUB(NOW(), INTERVAL 13 HOUR), DATE_SUB(NOW(), INTERVAL 13 HOUR), 'Xe tải đổ dầu ra đường', 'Dầu nhớt tràn ra mặt đường, rất trơn trượt tại Q4', 'https://picsum.photos/400/300?random=15', 10.7580, 106.7010, 'high', 'pending', 'u2', NULL, 'https://picsum.photos/400/300?random=15', 'Quận 4, TP.HCM', 'Cầu Kênh Tẻ', TRUE),
('r16', DATE_SUB(NOW(), INTERVAL 14 HOUR), DATE_SUB(NOW(), INTERVAL 6 HOUR), 'Biển báo giao thông hỏng', 'Biển báo cấm rẽ trái bị xoay ngược hướng, gây nhầm lẫn', 'https://picsum.photos/400/300?random=16', 10.8200, 106.6920, 'low', 'processing', 'u3', 'u5', 'https://picsum.photos/400/300?random=16', 'Gò Vấp, TP.HCM', 'Giao lộ lớn', FALSE);

-- Thời điểm phân công cho báo cáo đã có nhân viên phụ trách (dùng cho thống kê "thời gian xử lý"):
-- đặt ở 1/3 khoảng created_at → updated_at để luôn nằm giữa hai mốc.
UPDATE reports
SET assigned_at = DATE_ADD(created_at, INTERVAL TIMESTAMPDIFF(SECOND, created_at, updated_at) DIV 3 SECOND)
WHERE assigned_staff_id IS NOT NULL AND assigned_at IS NULL;

-- --------------------------------------------------------
-- Table: activity_histories
-- Phụ thuộc: users
-- Model: ActivityHistory (AbstractEntity)
-- Columns: id, created_at, updated_at, actor_id, i18n_key, target_id
-- --------------------------------------------------------
INSERT INTO activity_histories (id, created_at, updated_at, actor_id, i18n_key, target_id) VALUES
('act1', DATE_SUB(NOW(), INTERVAL 15 MINUTE), DATE_SUB(NOW(), INTERVAL 15 MINUTE), 'u2', 'Trần Thị User activity.report.created', 'r1'),
('act2', DATE_SUB(NOW(), INTERVAL 45 MINUTE), DATE_SUB(NOW(), INTERVAL 45 MINUTE), 'u3', 'Lê Hữu Cư Dân activity.report.created', 'r2'),
('act3', DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_SUB(NOW(), INTERVAL 1 HOUR), 'u2', 'Trần Thị User activity.report.created', 'r3'),
('act4', DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 2 HOUR), 'u3', 'Lê Hữu Cư Dân activity.report.created', 'r4'),
('act5', DATE_SUB(NOW(), INTERVAL 3 HOUR), DATE_SUB(NOW(), INTERVAL 3 HOUR), 'u7', 'Phạm Minh Khách Hàng activity.report.created', 'r5'),
('act6', DATE_SUB(NOW(), INTERVAL 4 HOUR), DATE_SUB(NOW(), INTERVAL 4 HOUR), 'u7', 'client3@gmail.com activity.user.registered', 'u7'),
('act7', DATE_SUB(NOW(), INTERVAL 6 HOUR), DATE_SUB(NOW(), INTERVAL 6 HOUR), 'u2', 'user@gmail.com activity.user.registered', 'u2'),
('act8', DATE_SUB(NOW(), INTERVAL 8 HOUR), DATE_SUB(NOW(), INTERVAL 8 HOUR), 'u3', 'cudan@gmail.com activity.user.registered', 'u3');

-- --------------------------------------------------------
-- Table: notifications
-- Phụ thuộc: users
-- Model: Notification (AbstractEntity)
-- Columns: id, created_at, updated_at, title, message, user_id, is_read, action_data
-- --------------------------------------------------------
INSERT INTO notifications (id, created_at, updated_at, title, message, user_id, is_read, action_data) VALUES
('n1', NOW(), NOW(), 'Bảo trì hệ thống', 'Hệ thống sẽ bảo trì vào 00:00 ngày mai', NULL, 0, '{"type": "system", "action": "maintenance"}'),
('n2', NOW(), NOW(), 'Phản ánh đang được xử lý', 'Phản ánh "Rác thải đổ bừa bãi" của bạn đang được xử lý', 'u3', 0, '{"type": "report", "reportId": "r2"}'),
('n3', NOW(), NOW(), 'Cảnh báo kẹt xe', 'Kẹt xe nghiêm trọng tại ngã tư XYZ', 'u2', 0, '{"type": "traffic", "reportId": "r3"}'),
('n4', NOW(), NOW(), 'Phản ánh đã xử lý xong', 'Phản ánh "Đường ống nước vỡ" đã được khắc phục hoàn tất', 'u3', 1, '{"type": "report", "reportId": "r4"}');

-- --------------------------------------------------------
-- Table: user_notification_states
-- Phụ thuộc: users, notifications
-- Model: UserNotificationState (AbstractEntity)
-- Columns: id, created_at, updated_at, is_read, notification_id, user_id
-- --------------------------------------------------------
INSERT INTO user_notification_states (id, created_at, updated_at, is_read, notification_id, user_id) VALUES
('uns1', NOW(), NOW(), 0, 'n1', 'u1'),
('uns2', NOW(), NOW(), 1, 'n1', 'u2'),
('uns3', NOW(), NOW(), 0, 'n1', 'u3'),
('uns4', NOW(), NOW(), 0, 'n1', 'u4'),
('uns5', NOW(), NOW(), 0, 'n1', 'u5'),
('uns6', NOW(), NOW(), 0, 'n1', 'u6'),
('uns7', NOW(), NOW(), 0, 'n1', 'u7');

-- --------------------------------------------------------
-- Table: device_tokens
-- Phụ thuộc: users
-- Model: DeviceToken (AbstractEntity)
-- Columns: id, created_at, updated_at, fcm_token, platform, device_name, last_used_at, user_id
-- --------------------------------------------------------
INSERT INTO device_tokens (id, created_at, updated_at, fcm_token, platform, device_name, last_used_at, user_id) VALUES
('dt1', NOW(), NOW(), 'sample-fcm-token-user-2-web', 'web', 'Web Browser Chrome', NOW(), 'u2'),
('dt2', NOW(), NOW(), 'sample-fcm-token-user-3-android', 'android', 'Samsung Galaxy S23', NOW(), 'u3'),
('dt3', NOW(), NOW(), 'sample-fcm-token-admin-1-web', 'web', 'Admin Desktop Edge', NOW(), 'u1'),
('dt4', NOW(), NOW(), 'sample-fcm-token-staff-1-android', 'android', 'Staff Device Xiaomi', NOW(), 'u5');

-- --------------------------------------------------------
-- Table: conversations
-- Phụ thuộc: (Không)
-- Model: Conversation
-- Columns: id, name, conversation_avatar, conversation_type, participant_hash, created_at, last_message_id, last_message_content, last_message_time
-- --------------------------------------------------------
INSERT INTO conversations (id, name, conversation_avatar, conversation_type, participant_hash, created_at, last_message_id, last_message_content, last_message_time) VALUES
('c1', 'Trần Thị User, Lê Hữu Cư Dân', NULL, 'PRIVATE', 'u2_u3', NOW(), 'm2', 'Chào bạn, mình thấy tin phản ánh của bạn.', NOW());

-- --------------------------------------------------------
-- Table: conversation_participants
-- Phụ thuộc: conversations, users
-- Model: ConversationParticipant
-- Columns: id, conversation_id, user_id, joined_at
-- --------------------------------------------------------
INSERT INTO conversation_participants (id, conversation_id, user_id, joined_at) VALUES
('cp1', 'c1', 'u2', NOW()),
('cp2', 'c1', 'u3', NOW());

-- --------------------------------------------------------
-- Table: chat_messages
-- Phụ thuộc: conversations, users
-- Model: ChatMessage
-- Columns: id, conversation_id, sender_id, content, message_type, sent_at
-- --------------------------------------------------------
INSERT INTO chat_messages (id, conversation_id, sender_id, content, message_type, sent_at) VALUES
('m1', 'c1', 'u2', 'Xin chào!', 'text', DATE_SUB(NOW(), INTERVAL 5 MINUTE)),
('m2', 'c1', 'u3', 'Chào bạn, mình thấy tin phản ánh của bạn.', 'text', DATE_SUB(NOW(), INTERVAL 2 MINUTE));

-- --------------------------------------------------------
-- Table: message_media
-- Phụ thuộc: chat_messages
-- Model: MessageMedia
-- Columns: id, message_id, file_name, thumbnail_url, file_type, uploaded_at
-- --------------------------------------------------------
INSERT INTO message_media (id, message_id, file_name, thumbnail_url, file_type, uploaded_at) VALUES
(1, 'm1', 'sample_image.jpg', 'https://picsum.photos/400/300?random=5', 'IMAGE', NOW());

-- ========================================================
-- Nhờ làm giùm (staff delegation) + Ví staff
-- Số tiền theo cấu hình mặc định: hoa hồng thấp/TB/cao/nghiêm trọng = 2.000/5.000/7.000/10.000đ,
-- tỷ lệ bonus 50/40/30/20% → bonus 1.000/2.000/2.100/2.000đ (đã chốt vào từng yêu cầu).
--
-- Kịch bản test (mật khẩu Ad123456!):
--   staff1 (u5, ví 20.900đ):
--     - r2, r6, r12, r16, r20, r36: đang xử lý, chưa có yêu cầu → hiện nút "Nhờ làm giùm"
--     - r32: đã nhờ staff2, đang chờ trả lời → banner + nút "Huỷ yêu cầu"
--     - r33: staff2 đã nhận → task đã chuyển sang staff2
--     - r34: đã nhờ staff2 nhưng quá hạn 24h → job hết hạn chạy ~1 phút sau khi backend khởi động, hoàn 1.000đ (ví → 21.900đ)
--     - r39: đang xử lý lại (đã nhận hoa hồng, bị phạt 1 lần) → KHÔNG được nhờ
--     - Tab "Được nhờ": dg4 đã hoàn tất (nhận 10.000đ hoa hồng + 2.000đ bonus từ staff2)
--   staff2 (u6, ví 5.000đ):
--     - Tab "Được nhờ": dg1 (r32) chờ trả lời → "Nhận làm" / "Từ chối"; dg3 (r34) quá hạn → nhận sẽ báo hết hạn
--     - r33: task được nhờ đã nhận → hoàn tất để nhận 7.000đ hoa hồng + 2.100đ bonus
--     - r8, r37: đang xử lý, có thể nhờ người khác
--   staff3 (u8, chưa có ví = 0đ): r38 → nút "Nhờ làm giùm" bị khoá vì số dư không đủ
--   Lịch sử: dg5 bị từ chối (staff1 → staff3), dg6 bị huỷ (staff2 → staff4), đều đã hoàn tiền
-- ========================================================

-- --------------------------------------------------------
-- Table: reports (bổ sung cho nhờ làm giùm)
-- Columns: như trên + assigned_at, resolved_at, resolved_note, base_commission, commission_awarded,
--          rehandling_penalty_count, total_commission_deducted
-- --------------------------------------------------------
INSERT INTO reports (id, created_at, updated_at, title, description, image_url, latitude, longitude, severity, status, user_id, assigned_staff_id, image_urls, address, location_description, is_anonymous, assigned_at, resolved_at, resolved_note, base_commission, commission_awarded, rehandling_penalty_count, total_commission_deducted) VALUES
-- Đã hoàn tất: nguồn số dư ví
('r40', DATE_SUB(NOW(), INTERVAL 10080 MINUTE), DATE_SUB(NOW(), INTERVAL 8640 MINUTE), 'Ống nước rò rỉ trước chợ', 'Ống cấp nước rò rỉ liên tục trước cổng chợ Tân Định', 'https://picsum.photos/400/300?random=40', 10.7905, 106.6905, 'high', 'processed', 'u2', 'u6', 'https://picsum.photos/400/300?random=40', 'Quận 1, TP.HCM', 'Cổng chợ', FALSE, DATE_SUB(NOW(), INTERVAL 9800 MINUTE), DATE_SUB(NOW(), INTERVAL 8640 MINUTE), 'Đã thay đoạn ống rò rỉ', 7000, TRUE, 0, 0),
('r30', DATE_SUB(NOW(), INTERVAL 8640 MINUTE), DATE_SUB(NOW(), INTERVAL 7200 MINUTE), 'Trụ điện nghiêng sắp đổ', 'Trụ điện bị xe tông nghiêng hẳn sang một bên', 'https://picsum.photos/400/300?random=30', 10.7810, 106.6950, 'critical', 'processed', 'u2', 'u5', 'https://picsum.photos/400/300?random=30', 'Quận 3, TP.HCM', 'Đầu hẻm 102', FALSE, DATE_SUB(NOW(), INTERVAL 8000 MINUTE), DATE_SUB(NOW(), INTERVAL 7200 MINUTE), 'Đã chằng néo và báo điện lực', 10000, TRUE, 0, 0),
('r35', DATE_SUB(NOW(), INTERVAL 5760 MINUTE), DATE_SUB(NOW(), INTERVAL 2880 MINUTE), 'Cống thoát nước bị tắc', 'Cống tắc khiến nước mưa ứ đọng cả đoạn đường', 'https://picsum.photos/400/300?random=35', 10.7695, 106.6820, 'critical', 'processed', 'u3', 'u5', 'https://picsum.photos/400/300?random=35', 'Quận 10, TP.HCM', 'Trước trường tiểu học', FALSE, DATE_SUB(NOW(), INTERVAL 4200 MINUTE), DATE_SUB(NOW(), INTERVAL 2880 MINUTE), 'Đã nạo vét cống', 10000, TRUE, 0, 0),
-- Đang xử lý lại (đã nhận hoa hồng + bị phạt 20%) → không được nhờ
('r39', DATE_SUB(NOW(), INTERVAL 7200 MINUTE), DATE_SUB(NOW(), INTERVAL 4320 MINUTE), 'Nắp hố ga bị vỡ', 'Nắp hố ga vỡ, đã sửa nhưng người dân báo lại vẫn lún', 'https://picsum.photos/400/300?random=39', 10.7750, 106.6700, 'medium', 'processing', 'u3', 'u5', 'https://picsum.photos/400/300?random=39', 'Quận 10, TP.HCM', 'Giữa lòng đường', FALSE, DATE_SUB(NOW(), INTERVAL 7000 MINUTE), DATE_SUB(NOW(), INTERVAL 5760 MINUTE), 'Đã thay nắp tạm', 5000, TRUE, 1, 1000),
-- Đang xử lý, gắn với các yêu cầu nhờ làm giùm
('r32', DATE_SUB(NOW(), INTERVAL 180 MINUTE), DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'Đèn tín hiệu giao thông chập chờn', 'Đèn đỏ lúc sáng lúc tắt tại giao lộ, dễ gây tai nạn', 'https://picsum.photos/400/300?random=32', 10.7680, 106.6660, 'medium', 'processing', 'u2', 'u5', 'https://picsum.photos/400/300?random=32', 'Quận 10, TP.HCM', 'Giao lộ 3/2 - Lý Thường Kiệt', FALSE, DATE_SUB(NOW(), INTERVAL 150 MINUTE), NULL, NULL, NULL, FALSE, 0, 0),
('r33', DATE_SUB(NOW(), INTERVAL 480 MINUTE), DATE_SUB(NOW(), INTERVAL 240 MINUTE), 'Cây xanh gãy cành nguy hiểm', 'Cành cây lớn gãy treo lơ lửng trên đường', 'https://picsum.photos/400/300?random=33', 10.7860, 106.7000, 'high', 'processing', 'u3', 'u6', 'https://picsum.photos/400/300?random=33', 'Quận 1, TP.HCM', 'Công viên Lê Văn Tám', FALSE, DATE_SUB(NOW(), INTERVAL 240 MINUTE), NULL, NULL, NULL, FALSE, 0, 0),
('r34', DATE_SUB(NOW(), INTERVAL 1700 MINUTE), DATE_SUB(NOW(), INTERVAL 1560 MINUTE), 'Rác tồn đọng ở hẻm 12', 'Rác chưa được thu gom 3 ngày, bốc mùi', 'https://picsum.photos/400/300?random=34', 10.7600, 106.6630, 'low', 'processing', 'u2', 'u5', 'https://picsum.photos/400/300?random=34', 'Quận 5, TP.HCM', 'Hẻm 12', FALSE, DATE_SUB(NOW(), INTERVAL 1650 MINUTE), NULL, NULL, NULL, FALSE, 0, 0),
('r36', DATE_SUB(NOW(), INTERVAL 1900 MINUTE), DATE_SUB(NOW(), INTERVAL 1680 MINUTE), 'Vạch kẻ đường bị mờ', 'Vạch qua đường cho người đi bộ gần như không còn thấy', 'https://picsum.photos/400/300?random=36', 10.7720, 106.6580, 'low', 'processing', 'u3', 'u5', 'https://picsum.photos/400/300?random=36', 'Quận 11, TP.HCM', 'Trước bệnh viện', FALSE, DATE_SUB(NOW(), INTERVAL 1850 MINUTE), NULL, NULL, NULL, FALSE, 0, 0),
('r37', DATE_SUB(NOW(), INTERVAL 1300 MINUTE), DATE_SUB(NOW(), INTERVAL 1140 MINUTE), 'Nước thải tràn ra vỉa hè', 'Nước thải từ quán ăn chảy tràn ra vỉa hè', 'https://picsum.photos/400/300?random=37', 10.8020, 106.7120, 'medium', 'processing', 'u2', 'u6', 'https://picsum.photos/400/300?random=37', 'Bình Thạnh, TP.HCM', 'Dãy quán ăn', FALSE, DATE_SUB(NOW(), INTERVAL 1250 MINUTE), NULL, NULL, NULL, FALSE, 0, 0),
('r38', DATE_SUB(NOW(), INTERVAL 600 MINUTE), DATE_SUB(NOW(), INTERVAL 550 MINUTE), 'Biển tên đường bị mất', 'Biển tên đường ở ngã ba bị mất, khó tìm đường', 'https://picsum.photos/400/300?random=38', 10.8100, 106.6650, 'low', 'processing', 'u3', 'u8', 'https://picsum.photos/400/300?random=38', 'Tân Bình, TP.HCM', 'Ngã ba', FALSE, DATE_SUB(NOW(), INTERVAL 550 MINUTE), NULL, NULL, NULL, FALSE, 0, 0);

-- --------------------------------------------------------
-- Table: report_delegations
-- Phụ thuộc: reports, users
-- Model: ReportDelegation (AbstractEntity)
-- Columns: id, created_at, updated_at, report_id, requester_id, helper_id, status, severity, rate_percent,
--          commission_amount, bonus_amount, note, expires_at, responded_at, completed_at
-- --------------------------------------------------------
INSERT INTO report_delegations (id, created_at, updated_at, report_id, requester_id, helper_id, status, severity, rate_percent, commission_amount, bonus_amount, note, expires_at, responded_at, completed_at) VALUES
('dg1', DATE_SUB(NOW(), INTERVAL 60 MINUTE), DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'r32', 'u5', 'u6', 'PENDING', 'medium', 40, 5000, 2000, 'Mình đang xử lý việc khác ở Q7, nhờ bạn giúp nhé', DATE_ADD(NOW(), INTERVAL 1380 MINUTE), NULL, NULL),
('dg2', DATE_SUB(NOW(), INTERVAL 360 MINUTE), DATE_SUB(NOW(), INTERVAL 240 MINUTE), 'r33', 'u5', 'u6', 'ACCEPTED', 'high', 30, 7000, 2100, 'Cần người có thang, nhờ bạn hỗ trợ', DATE_ADD(NOW(), INTERVAL 1080 MINUTE), DATE_SUB(NOW(), INTERVAL 240 MINUTE), NULL),
('dg3', DATE_SUB(NOW(), INTERVAL 1560 MINUTE), DATE_SUB(NOW(), INTERVAL 1560 MINUTE), 'r34', 'u5', 'u6', 'PENDING', 'low', 50, 2000, 1000, NULL, DATE_SUB(NOW(), INTERVAL 120 MINUTE), NULL, NULL),
('dg4', DATE_SUB(NOW(), INTERVAL 4320 MINUTE), DATE_SUB(NOW(), INTERVAL 2879 MINUTE), 'r35', 'u6', 'u5', 'COMPLETED', 'critical', 20, 10000, 2000, 'Khu vực này bạn rành hơn mình', DATE_SUB(NOW(), INTERVAL 2880 MINUTE), DATE_SUB(NOW(), INTERVAL 4200 MINUTE), DATE_SUB(NOW(), INTERVAL 2879 MINUTE)),
('dg5', DATE_SUB(NOW(), INTERVAL 1800 MINUTE), DATE_SUB(NOW(), INTERVAL 1680 MINUTE), 'r36', 'u5', 'u8', 'DECLINED', 'low', 50, 2000, 1000, NULL, DATE_SUB(NOW(), INTERVAL 360 MINUTE), DATE_SUB(NOW(), INTERVAL 1680 MINUTE), NULL),
('dg6', DATE_SUB(NOW(), INTERVAL 1200 MINUTE), DATE_SUB(NOW(), INTERVAL 1140 MINUTE), 'r37', 'u6', 'u9', 'CANCELLED', 'medium', 40, 5000, 2000, NULL, DATE_ADD(NOW(), INTERVAL 240 MINUTE), DATE_SUB(NOW(), INTERVAL 1140 MINUTE), NULL);

-- --------------------------------------------------------
-- Table: staff_wallets
-- Phụ thuộc: users
-- Model: StaffWallet (AbstractEntity)
-- Columns: id, created_at, updated_at, user_id, balance
-- Số dư = balance_after của giao dịch mới nhất bên dưới
-- --------------------------------------------------------
INSERT INTO staff_wallets (id, created_at, updated_at, user_id, balance) VALUES
('w5', DATE_SUB(NOW(), INTERVAL 8000 MINUTE), DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'u5', 20900),
('w6', DATE_SUB(NOW(), INTERVAL 9800 MINUTE), DATE_SUB(NOW(), INTERVAL 1140 MINUTE), 'u6', 5000);

-- --------------------------------------------------------
-- Table: staff_wallet_transactions
-- Phụ thuộc: staff_wallets, reports, report_delegations
-- Model: StaffWalletTransaction (AbstractEntity)
-- Columns: id, created_at, updated_at, wallet_id, type, amount, balance_after, report_id, delegation_id, title_i18n_key, title_params
-- Mỗi yêu cầu: HOLD = bonus; từ chối/huỷ/hết hạn → REFUND = bonus; hoàn tất → BONUS = bonus cho người làm giùm
-- --------------------------------------------------------
INSERT INTO staff_wallet_transactions (id, created_at, updated_at, wallet_id, type, amount, balance_after, report_id, delegation_id, title_i18n_key, title_params) VALUES
-- staff1 (u5): 0 → 20.900đ
('wt1', DATE_SUB(NOW(), INTERVAL 7200 MINUTE), DATE_SUB(NOW(), INTERVAL 7200 MINUTE), 'w5', 'COMMISSION', 10000, 10000, 'r30', NULL, 'wallet.transaction.commission.title', 'Trụ điện nghiêng sắp đổ'),
('wt2', DATE_SUB(NOW(), INTERVAL 5760 MINUTE), DATE_SUB(NOW(), INTERVAL 5760 MINUTE), 'w5', 'COMMISSION', 5000, 15000, 'r39', NULL, 'wallet.transaction.commission.title', 'Nắp hố ga bị vỡ'),
('wt3', DATE_SUB(NOW(), INTERVAL 4320 MINUTE), DATE_SUB(NOW(), INTERVAL 4320 MINUTE), 'w5', 'PENALTY_DEDUCTION', 1000, 14000, 'r39', NULL, 'wallet.transaction.penalty.title', 'Nắp hố ga bị vỡ'),
('wt4', DATE_SUB(NOW(), INTERVAL 2880 MINUTE), DATE_SUB(NOW(), INTERVAL 2880 MINUTE), 'w5', 'COMMISSION', 10000, 24000, 'r35', NULL, 'wallet.transaction.commission.title', 'Cống thoát nước bị tắc'),
('wt5', DATE_SUB(NOW(), INTERVAL 2879 MINUTE), DATE_SUB(NOW(), INTERVAL 2879 MINUTE), 'w5', 'DELEGATION_BONUS', 2000, 26000, 'r35', 'dg4', 'wallet.transaction.delegation_bonus.title', 'Cống thoát nước bị tắc'),
('wt6', DATE_SUB(NOW(), INTERVAL 1800 MINUTE), DATE_SUB(NOW(), INTERVAL 1800 MINUTE), 'w5', 'DELEGATION_HOLD', 1000, 25000, 'r36', 'dg5', 'wallet.transaction.delegation_hold.title', 'Vạch kẻ đường bị mờ'),
('wt7', DATE_SUB(NOW(), INTERVAL 1680 MINUTE), DATE_SUB(NOW(), INTERVAL 1680 MINUTE), 'w5', 'DELEGATION_REFUND', 1000, 26000, 'r36', 'dg5', 'wallet.transaction.delegation_refund.title', 'Vạch kẻ đường bị mờ'),
('wt8', DATE_SUB(NOW(), INTERVAL 1560 MINUTE), DATE_SUB(NOW(), INTERVAL 1560 MINUTE), 'w5', 'DELEGATION_HOLD', 1000, 25000, 'r34', 'dg3', 'wallet.transaction.delegation_hold.title', 'Rác tồn đọng ở hẻm 12'),
('wt9', DATE_SUB(NOW(), INTERVAL 360 MINUTE), DATE_SUB(NOW(), INTERVAL 360 MINUTE), 'w5', 'DELEGATION_HOLD', 2100, 22900, 'r33', 'dg2', 'wallet.transaction.delegation_hold.title', 'Cây xanh gãy cành nguy hiểm'),
('wt10', DATE_SUB(NOW(), INTERVAL 60 MINUTE), DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'w5', 'DELEGATION_HOLD', 2000, 20900, 'r32', 'dg1', 'wallet.transaction.delegation_hold.title', 'Đèn tín hiệu giao thông chập chờn'),
-- staff2 (u6): 0 → 5.000đ
('wt11', DATE_SUB(NOW(), INTERVAL 8640 MINUTE), DATE_SUB(NOW(), INTERVAL 8640 MINUTE), 'w6', 'COMMISSION', 7000, 7000, 'r40', NULL, 'wallet.transaction.commission.title', 'Ống nước rò rỉ trước chợ'),
('wt12', DATE_SUB(NOW(), INTERVAL 4320 MINUTE), DATE_SUB(NOW(), INTERVAL 4320 MINUTE), 'w6', 'DELEGATION_HOLD', 2000, 5000, 'r35', 'dg4', 'wallet.transaction.delegation_hold.title', 'Cống thoát nước bị tắc'),
('wt13', DATE_SUB(NOW(), INTERVAL 1200 MINUTE), DATE_SUB(NOW(), INTERVAL 1200 MINUTE), 'w6', 'DELEGATION_HOLD', 2000, 3000, 'r37', 'dg6', 'wallet.transaction.delegation_hold.title', 'Nước thải tràn ra vỉa hè'),
('wt14', DATE_SUB(NOW(), INTERVAL 1140 MINUTE), DATE_SUB(NOW(), INTERVAL 1140 MINUTE), 'w6', 'DELEGATION_REFUND', 2000, 5000, 'r37', 'dg6', 'wallet.transaction.delegation_refund.title', 'Nước thải tràn ra vỉa hè');

-- Thông báo nhờ làm giùm (type STAFF_DELEGATION, bấm vào mở chi tiết report)
INSERT INTO notifications (id, created_at, updated_at, title, message, user_id, is_read, action_data) VALUES
('n5', DATE_SUB(NOW(), INTERVAL 60 MINUTE), DATE_SUB(NOW(), INTERVAL 60 MINUTE), 'Có yêu cầu nhờ làm giùm', 'Nguyễn Văn Nhân Viên nhờ bạn làm giùm phản ánh "Đèn tín hiệu giao thông chập chờn". Bạn sẽ nhận hoa hồng của task và thêm 2,000đ bonus.', 'u6', 0, '{"type": "STAFF_DELEGATION", "payload": {"delegationId":"dg1","reportId":"r32"}}'),
('n6', DATE_SUB(NOW(), INTERVAL 240 MINUTE), DATE_SUB(NOW(), INTERVAL 240 MINUTE), 'Yêu cầu nhờ làm giùm đã được nhận', 'Lê Thị Hỗ Trợ đã nhận làm giùm phản ánh "Cây xanh gãy cành nguy hiểm". Bonus đã giữ sẽ được chuyển khi task hoàn tất.', 'u5', 0, '{"type": "STAFF_DELEGATION", "payload": {"delegationId":"dg2","reportId":"r33"}}');

SET FOREIGN_KEY_CHECKS = 1;
