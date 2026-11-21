package com.vn.smart_space.service.admin;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.mail.MailSendException;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.request.admin.CreateAdminRequest;
import com.vn.smart_space.dto.request.admin.UpdateAdminStatusRequest;
import com.vn.smart_space.dto.response.admin.AdminAccountListResponse;
import com.vn.smart_space.dto.response.admin.AdminAccountResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.exception.UnauthorizedException;
import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.auth.IAuthenticationService;
import com.vn.smart_space.service.mail.IMailService;

@ExtendWith(MockitoExtension.class)
class AdminAccountServiceImplTest {

    private static final String ME = "admin-me";
    private static final String OTHER = "admin-other";

    @Mock
    UserRepository userRepository;
    @Mock
    ActivityHistoryRepository activityHistoryRepository;
    @Mock
    PasswordEncoder passwordEncoder;
    @Mock
    IMailService mailService;
    @Mock
    IAuthenticationService authenticationService;

    @InjectMocks
    AdminAccountServiceImpl service;

    private static User user(String id, ERole role, EUserStatus status) {
        User u = User.builder()
                .fullName("Name " + id)
                .email(id + "@example.com")
                .role(role)
                .status(status)
                .build();
        u.setId(id);
        return u;
    }

    // ---------- list ----------

    // Test Case ID: SMP-262
    // Description: Kiểm tra getAdmins giới hạn pageSize tối đa 50, đánh dấu currentUser và trả về summary chính xác.
    @Test
    @DisplayName("getAdmins: đánh dấu currentUser, summary tính trên toàn bộ admin, page size bị chặn tối đa")
    void getAdmins_marksCurrentUserAndClampsSize() {
        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        when(userRepository.findStaffs(eq(ERole.admin), eq(null), eq(null), eq("an"), pageable.capture()))
                .thenReturn(new PageImpl<>(List.of(
                        user(ME, ERole.admin, EUserStatus.active),
                        user(OTHER, ERole.admin, EUserStatus.blocked))));
        when(userRepository.countByRole(ERole.admin)).thenReturn(2L);
        when(userRepository.countByRoleAndStatus(ERole.admin, EUserStatus.active)).thenReturn(1L);
        when(userRepository.countByRoleAndStatus(ERole.admin, EUserStatus.blocked)).thenReturn(1L);

        AdminAccountListResponse res = service.getAdmins(0, 500, "  an ", "all", ME);

        assertEquals(50, pageable.getValue().getPageSize());
        assertEquals(0, pageable.getValue().getPageNumber());
        assertEquals(1, res.getAdmins().getCurrentPage());
        assertTrue(res.getAdmins().getContent().get(0).isCurrentUser());
        assertFalse(res.getAdmins().getContent().get(1).isCurrentUser());
        assertEquals(2, res.getSummary().getTotal());
        assertEquals(1, res.getSummary().getBlocked());
    }

    // ---------- create ----------

    @Nested
    @DisplayName("Tạo quản trị viên")
    class Create {

        private final CreateAdminRequest request =
                new CreateAdminRequest(" New Admin ", " new@example.com ", "");

        // Test Case ID: SMP-263
        // Description: Từ chối tạo admin mới khi email (sau trim) đã tồn tại với role admin, không lưu và không gửi mail.
        @Test
        @DisplayName("email đã có tài khoản admin → auth.email.exists, không tạo, không gửi mail")
        void duplicateEmail_isRejected() {
            when(userRepository.existsByEmailAndRole("new@example.com", ERole.admin)).thenReturn(true);

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.createAdmin(request, ME));

            assertEquals("auth.email.exists", ex.getMessage());
            verify(userRepository, never()).saveAndFlush(any());
            verifyNoInteractions(mailService);
        }

        // Test Case ID: SMP-264
        // Description: Chuyển DataIntegrityViolationException khi lưu đồng thời trùng email thành BadRequestException auth.email.exists.
        @Test
        @DisplayName("vi phạm unique khi tạo đồng thời → auth.email.exists, không gửi mail")
        void concurrentDuplicate_isRejected() {
            when(userRepository.existsByEmailAndRole("new@example.com", ERole.admin)).thenReturn(false);
            when(passwordEncoder.encode(anyString())).thenReturn("hashed");
            when(userRepository.saveAndFlush(any(User.class)))
                    .thenThrow(new DataIntegrityViolationException("uk_email_role"));

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.createAdmin(request, ME));

            assertEquals("auth.email.exists", ex.getMessage());
            verifyNoInteractions(mailService);
        }

        // Test Case ID: SMP-265
        // Description: Tạo admin thành công: hash mật khẩu, chuẩn hóa SĐT rỗng thành null, ghi activity log và gửi email.
        @Test
        @DisplayName("thành công → role admin, active, mật khẩu được hash, ghi log, gửi mail mật khẩu gốc")
        void success_createsAdminLogsAndMails() {
            when(userRepository.existsByEmailAndRole("new@example.com", ERole.admin)).thenReturn(false);
            when(passwordEncoder.encode(anyString())).thenReturn("hashed");
            when(userRepository.saveAndFlush(any(User.class))).thenAnswer(inv -> {
                User saved = inv.getArgument(0);
                saved.setId("new-id");
                return saved;
            });
            when(userRepository.findById(ME)).thenReturn(Optional.of(user(ME, ERole.admin, EUserStatus.active)));

            AdminAccountResponse res = service.createAdmin(request, ME);

            ArgumentCaptor<User> saved = ArgumentCaptor.forClass(User.class);
            verify(userRepository).saveAndFlush(saved.capture());
            assertEquals(ERole.admin, saved.getValue().getRole());
            assertEquals(EUserStatus.active, saved.getValue().getStatus());
            assertEquals("hashed", saved.getValue().getPassword());
            assertEquals("New Admin", saved.getValue().getFullName());
            assertEquals(null, saved.getValue().getPhone(), "SĐT rỗng được lưu là null");

            ArgumentCaptor<String> rawPassword = ArgumentCaptor.forClass(String.class);
            verify(passwordEncoder).encode(rawPassword.capture());
            verify(mailService).sendAdminCredentialsEmail(
                    eq("new@example.com"), eq("New Admin"), eq(rawPassword.getValue()), any());

            ArgumentCaptor<ActivityHistory> activity = ArgumentCaptor.forClass(ActivityHistory.class);
            verify(activityHistoryRepository).save(activity.capture());
            assertEquals("activity.admin.created|Name admin-me|New Admin", activity.getValue().getI18nKey());
            assertEquals("new-id", activity.getValue().getTargetId());

            assertEquals("new-id", res.getId());
            assertFalse(res.isCurrentUser());
        }

        // Test Case ID: SMP-266
        // Description: Ném BadRequestException mail.admin.credentials.send_failed khi gửi email thông tin đăng nhập thất bại.
        @Test
        @DisplayName("gửi mail thất bại → mail.admin.credentials.send_failed (transaction rollback)")
        void mailFailure_isReported() {
            when(userRepository.existsByEmailAndRole("new@example.com", ERole.admin)).thenReturn(false);
            when(passwordEncoder.encode(anyString())).thenReturn("hashed");
            when(userRepository.saveAndFlush(any(User.class))).thenAnswer(inv -> inv.getArgument(0));
            doThrow(new MailSendException("smtp down"))
                    .when(mailService).sendAdminCredentialsEmail(anyString(), anyString(), anyString(), any());

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.createAdmin(request, ME));

            assertEquals("mail.admin.credentials.send_failed", ex.getMessage());
        }
    }

    // ---------- status ----------

    @Nested
    @DisplayName("Khóa / mở khóa quản trị viên")
    class Status {

        // Test Case ID: SMP-267
        // Description: Từ chối khi admin tự thay đổi trạng thái của chính mình và không tương tác DB/auth.
        @Test
        @DisplayName("tự thay đổi trạng thái chính mình → admin.account.cannot_lock_self")
        void self_isRejected() {
            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.updateAdminStatus(ME, new UpdateAdminStatusRequest("blocked"), ME));

            assertEquals("admin.account.cannot_lock_self", ex.getMessage());
            verifyNoInteractions(userRepository, authenticationService);
        }

        // Test Case ID: SMP-268
        // Description: Từ chối cập nhật trạng thái admin khi giá trị status không hợp lệ ("deleted").
        @Test
        @DisplayName("status không hợp lệ → admin.account.status_invalid")
        void invalidStatus_isRejected() {
            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.updateAdminStatus(OTHER, new UpdateAdminStatusRequest("deleted"), ME));

            assertEquals("admin.account.status_invalid", ex.getMessage());
        }

        // Test Case ID: SMP-269
        // Description: Trả về ResourceNotFoundException admin.account.not_found khi tài khoản đích không phải role admin.
        @Test
        @DisplayName("đối tượng không phải admin → admin.account.not_found (không lộ tài khoản staff/client)")
        void nonAdminTarget_isNotFound() {
            when(userRepository.lockByRoleAndStatus(ERole.admin, EUserStatus.active))
                    .thenReturn(List.of(user(ME, ERole.admin, EUserStatus.active)));
            when(userRepository.findById("staff-1"))
                    .thenReturn(Optional.of(user("staff-1", ERole.staff, EUserStatus.active)));

            ResourceNotFoundException ex = assertThrows(ResourceNotFoundException.class,
                    () -> service.updateAdminStatus("staff-1", new UpdateAdminStatusRequest("blocked"), ME));

            assertEquals("admin.account.not_found", ex.getMessage());
            verify(userRepository, never()).save(any());
        }

        // Test Case ID: SMP-270
        // Description: Khóa tài khoản admin khác thành công: lưu blocked, thu hồi phiên truy cập và ghi activity log.
        @Test
        @DisplayName("khóa admin khác → lưu blocked, thu hồi phiên, ghi log")
        void block_revokesAccessAndLogs() {
            User me = user(ME, ERole.admin, EUserStatus.active);
            User other = user(OTHER, ERole.admin, EUserStatus.active);
            when(userRepository.lockByRoleAndStatus(ERole.admin, EUserStatus.active)).thenReturn(List.of(me, other));
            when(userRepository.findById(OTHER)).thenReturn(Optional.of(other));
            when(userRepository.findById(ME)).thenReturn(Optional.of(me));

            service.updateAdminStatus(OTHER, new UpdateAdminStatusRequest("BLOCKED"), ME);

            assertEquals(EUserStatus.blocked, other.getStatus());
            verify(userRepository).save(other);
            verify(authenticationService).revokeUserAccess(OTHER);
            verify(authenticationService, never()).restoreUserAccess(anyString());

            ArgumentCaptor<ActivityHistory> activity = ArgumentCaptor.forClass(ActivityHistory.class);
            verify(activityHistoryRepository).save(activity.capture());
            assertEquals("activity.admin.status_updated|Name admin-me|Name admin-other|blocked",
                    activity.getValue().getI18nKey());
        }

        // Test Case ID: SMP-271
        // Description: Từ chối thao tác khóa khi người gọi đã bị khóa đồng thời trước đó (auth.account.blocked).
        @Test
        @DisplayName("người gọi đã bị khóa bởi yêu cầu đồng thời → auth.account.blocked, không khóa thêm")
        void callerBlockedConcurrently_isRejected() {
            User other = user(OTHER, ERole.admin, EUserStatus.active);
            // Sau khi chờ lock, chỉ còn OTHER active (ME vừa bị OTHER khóa và đã commit)
            when(userRepository.lockByRoleAndStatus(ERole.admin, EUserStatus.active)).thenReturn(List.of(other));
            when(userRepository.findById(OTHER)).thenReturn(Optional.of(other));

            UnauthorizedException ex = assertThrows(UnauthorizedException.class,
                    () -> service.updateAdminStatus(OTHER, new UpdateAdminStatusRequest("blocked"), ME));

            assertEquals("auth.account.blocked", ex.getMessage());
            assertEquals(EUserStatus.active, other.getStatus());
            verify(userRepository, never()).save(any());
            verifyNoInteractions(authenticationService);
        }

        // Test Case ID: SMP-272
        // Description: Mở khóa tài khoản admin thành công, khôi phục phiên truy cập và không cần khóa danh sách admin.
        @Test
        @DisplayName("mở khóa → lưu active, gỡ cờ chặn, không cần lock danh sách admin")
        void unblock_restoresAccess() {
            User other = user(OTHER, ERole.admin, EUserStatus.blocked);
            when(userRepository.findById(OTHER)).thenReturn(Optional.of(other));
            when(userRepository.findById(ME)).thenReturn(Optional.of(user(ME, ERole.admin, EUserStatus.active)));

            service.updateAdminStatus(OTHER, new UpdateAdminStatusRequest("active"), ME);

            assertEquals(EUserStatus.active, other.getStatus());
            verify(authenticationService).restoreUserAccess(OTHER);
            verify(userRepository, never()).lockByRoleAndStatus(any(), any());
        }

        // Test Case ID: SMP-273
        // Description: Không lưu DB, không tác động phiên và không ghi log khi trạng thái mới trùng với trạng thái hiện tại.
        @Test
        @DisplayName("trạng thái không đổi → idempotent, không lưu, không ghi log")
        void sameStatus_isNoop() {
            User other = user(OTHER, ERole.admin, EUserStatus.blocked);
            when(userRepository.lockByRoleAndStatus(ERole.admin, EUserStatus.active))
                    .thenReturn(List.of(user(ME, ERole.admin, EUserStatus.active)));
            when(userRepository.findById(OTHER)).thenReturn(Optional.of(other));

            service.updateAdminStatus(OTHER, new UpdateAdminStatusRequest("blocked"), ME);

            verify(userRepository, never()).save(any());
            verifyNoInteractions(authenticationService, activityHistoryRepository);
        }
    }
}
