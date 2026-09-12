-- --------------------------------------------------------
-- Tệp dữ liệu mẫu (Seed Data) cho SmartSpace_Backend
-- Đảm bảo bạn đã chạy Hibernate để tạo cấu trúc bảng trước khi import file này, hoặc các table đã tồn tại
-- --------------------------------------------------------

-- Lưu ý: Mật khẩu của các user được mã hoá Bcrypt là 'Ad123456!'
-- Danh sách tài khoản đăng nhập mẫu:
-- 1/ Admin: admin@gmail.com (u1) | cudan2@gmail.com (u4) | Mật khẩu: Ad123456!
-- 2/ Staff: staff1@gmail.com (u5) | staff2@gmail.com (u6) | Mật khẩu: Ad123456!
-- 3/ Client: user@gmail.com (u2) | cudan@gmail.com (u3) | client3@gmail.com (u7) | Mật khẩu: Ad123456!

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
DELETE FROM reports;
DELETE FROM users;

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

-- --------------------------------------------------------
-- Table: reports
-- Phụ thuộc: users
-- Model: Report (AbstractEntity)
-- Columns: id, created_at, updated_at, title, description, image_url, latitude, longitude, severity, status, user_id, assigned_staff_id, image_urls, address, location_description, is_anonymous
-- --------------------------------------------------------
INSERT INTO reports (id, created_at, updated_at, title, description, image_url, latitude, longitude, severity, status, user_id, assigned_staff_id, image_urls, address, location_description, is_anonymous) VALUES
('r1', DATE_SUB(NOW(), INTERVAL 15 MINUTE), DATE_SUB(NOW(), INTERVAL 15 MINUTE), 'Đèn đường hỏng', 'Cột đèn số 12 bị hỏng không sáng vào ban đêm', 'https://picsum.photos/400/300?random=1', 10.762622, 106.660172, 'low', 'pending', 'u2', NULL, 'https://picsum.photos/400/300?random=1', 'Quận 10, TP.HCM', 'Gần ngã tư', FALSE),
('r2', DATE_SUB(NOW(), INTERVAL 45 MINUTE), DATE_SUB(NOW(), INTERVAL 10 MINUTE), 'Rác thải đổ bừa bãi', 'Khu vực công viên có người đổ rác bừa bãi gây bốc mùi', 'https://picsum.photos/400/300?random=2', 10.763622, 106.661172, 'medium', 'processing', 'u3', 'u5', 'https://picsum.photos/400/300?random=2', 'Quận 10, TP.HCM', 'Cạnh công viên', FALSE),
('r3', DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_SUB(NOW(), INTERVAL 1 HOUR), 'Tai nạn giao thông', 'Tai nạn ở ngã tư, cần hỗ trợ khẩn cấp', 'https://picsum.photos/400/300?random=3', 10.764622, 106.662172, 'critical', 'pending', 'u2', NULL, 'https://picsum.photos/400/300?random=3', 'Quận 10, TP.HCM', 'Ngã tư đường', TRUE),
('r4', DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'Đường ống nước vỡ', 'Nước ngập tràn ra đường hẻm 45', 'https://picsum.photos/400/300?random=4', 10.765622, 106.663172, 'high', 'processed', 'u3', 'u6', 'https://picsum.photos/400/300?random=4', 'Quận 10, TP.HCM', 'Hẻm 45', FALSE),
('r5', DATE_SUB(NOW(), INTERVAL 3 HOUR), DATE_SUB(NOW(), INTERVAL 3 HOUR), 'Cháy nhỏ tại kho hàng', 'Phát hiện khói bốc lên từ kho hàng bỏ hoang, cần PCCC', 'https://picsum.photos/400/300?random=5', 10.7769, 106.7009, 'critical', 'pending', 'u7', NULL, 'https://picsum.photos/400/300?random=5', 'Quận 1, TP.HCM', 'Kho hàng cũ', TRUE),
('r6', DATE_SUB(NOW(), INTERVAL 4 HOUR), DATE_SUB(NOW(), INTERVAL 1 HOUR), 'Hố tử thần trên đường', 'Hố sâu 50cm xuất hiện giữa đường Nguyễn Hữu Cảnh, nguy hiểm cho xe máy', 'https://picsum.photos/400/300?random=6', 10.7915, 106.7220, 'high', 'processing', 'u3', 'u5', 'https://picsum.photos/400/300?random=6', 'Bình Thạnh, TP.HCM', 'Giao lộ', FALSE),
('r7', DATE_SUB(NOW(), INTERVAL 5 HOUR), DATE_SUB(NOW(), INTERVAL 5 HOUR), 'Cây đổ chắn đường', 'Cây lớn bật gốc sau mưa, chắn hết làn xe tại Q7', 'https://picsum.photos/400/300?random=7', 10.7340, 106.7218, 'high', 'pending', 'u2', NULL, 'https://picsum.photos/400/300?random=7', 'Quận 7, TP.HCM', 'Đường lớn', FALSE),
('r8', DATE_SUB(NOW(), INTERVAL 6 HOUR), DATE_SUB(NOW(), INTERVAL 2 HOUR), 'Ngập nước kéo dài', 'Đường Tô Ngọc Vân ngập sâu 40cm, xe không lưu thông được', 'https://picsum.photos/400/300?random=8', 10.8488, 106.7590, 'medium', 'processing', 'u7', 'u6', 'https://picsum.photos/400/300?random=8', 'Thủ Đức, TP.HCM', 'Đoạn trũng', TRUE),
('r9', DATE_SUB(NOW(), INTERVAL 7 HOUR), DATE_SUB(NOW(), INTERVAL 3 HOUR), 'Tiếng ồn công trình', 'Công trường thi công gây ồn quá mức cho phép vào ban đêm', 'https://picsum.photos/400/300?random=9', 10.8015, 106.6527, 'low', 'processed', 'u2', 'u5', 'https://picsum.photos/400/300?random=9', 'Tân Bình, TP.HCM', 'Khu dân cư', FALSE),
('r10', DATE_SUB(NOW(), INTERVAL 8 HOUR), DATE_SUB(NOW(), INTERVAL 8 HOUR), 'Rò rỉ khí gas', 'Phát hiện mùi gas rò rỉ tại tòa nhà dân cư Q.Gò Vấp', 'https://picsum.photos/400/300?random=10', 10.8386, 106.6652, 'critical', 'pending', 'u3', NULL, 'https://picsum.photos/400/300?random=10', 'Gò Vấp, TP.HCM', 'Chung cư', TRUE),
('r11', DATE_SUB(NOW(), INTERVAL 9 HOUR), DATE_SUB(NOW(), INTERVAL 9 HOUR), 'Vỉa hè bị lấn chiếm', 'Hàng quán chiếm hết vỉa hè, người đi bộ phải đi dưới lòng đường', 'https://picsum.photos/400/300?random=11', 10.7724, 106.6681, 'low', 'rejected', 'u2', 'u6', 'https://picsum.photos/400/300?random=11', 'Quận 3, TP.HCM', 'Gần trường học', FALSE),
('r12', DATE_SUB(NOW(), INTERVAL 10 HOUR), DATE_SUB(NOW(), INTERVAL 4 HOUR), 'Đường dây điện đứt', 'Dây điện trung thế bị đứt rơi xuống đường tại Q10', 'https://picsum.photos/400/300?random=12', 10.7726, 106.6690, 'critical', 'processing', 'u3', 'u5', 'https://picsum.photos/400/300?random=12', 'Quận 10, TP.HCM', 'Ngã tư', TRUE),
('r13', DATE_SUB(NOW(), INTERVAL 11 HOUR), DATE_SUB(NOW(), INTERVAL 5 HOUR), 'Ô nhiễm kênh rạch', 'Nước kênh đen bốc mùi hôi thối tại Phú Nhuận', 'https://picsum.photos/400/300?random=13', 10.7990, 106.6830, 'medium', 'processed', 'u2', 'u6', 'https://picsum.photos/400/300?random=13', 'Phú Nhuận, TP.HCM', 'Dọc bờ kênh', FALSE),
('r14', DATE_SUB(NOW(), INTERVAL 12 HOUR), DATE_SUB(NOW(), INTERVAL 12 HOUR), 'Sạt lở bờ sông', 'Bờ sông Sài Gòn sạt lở nghiêm trọng, đe dọa nhà dân Q2', 'https://picsum.photos/400/300?random=14', 10.7870, 106.7450, 'high', 'pending', 'u7', NULL, 'https://picsum.photos/400/300?random=14', 'Quận 2, TP.HCM', 'Khu dân cư', FALSE),
('r15', DATE_SUB(NOW(), INTERVAL 13 HOUR), DATE_SUB(NOW(), INTERVAL 13 HOUR), 'Xe tải đổ dầu ra đường', 'Dầu nhớt tràn ra mặt đường, rất trơn trượt tại Q4', 'https://picsum.photos/400/300?random=15', 10.7580, 106.7010, 'high', 'pending', 'u2', NULL, 'https://picsum.photos/400/300?random=15', 'Quận 4, TP.HCM', 'Cầu Kênh Tẻ', TRUE),
('r16', DATE_SUB(NOW(), INTERVAL 14 HOUR), DATE_SUB(NOW(), INTERVAL 6 HOUR), 'Biển báo giao thông hỏng', 'Biển báo cấm rẽ trái bị xoay ngược hướng, gây nhầm lẫn', 'https://picsum.photos/400/300?random=16', 10.8200, 106.6920, 'low', 'processing', 'u3', 'u5', 'https://picsum.photos/400/300?random=16', 'Gò Vấp, TP.HCM', 'Giao lộ lớn', FALSE);

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

SET FOREIGN_KEY_CHECKS = 1;
