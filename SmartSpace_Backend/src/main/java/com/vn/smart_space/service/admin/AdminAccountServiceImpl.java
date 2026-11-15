package com.vn.smart_space.service.admin;

import java.util.List;
import java.util.Objects;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.mail.MailException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.admin.CreateAdminRequest;
import com.vn.smart_space.dto.request.admin.UpdateAdminStatusRequest;
import com.vn.smart_space.dto.response.admin.AdminAccountListResponse;
import com.vn.smart_space.dto.response.admin.AdminAccountResponse;
import com.vn.smart_space.dto.response.admin.AdminAccountSummaryResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.exception.UnauthorizedException;
import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.auth.IAuthenticationService;
import com.vn.smart_space.service.mail.IMailService;
import com.vn.smart_space.utils.PasswordGenerator;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminAccountServiceImpl implements IAdminAccountService {

        static final int MAX_PAGE_SIZE = 50;

        UserRepository userRepository;
        ActivityHistoryRepository activityHistoryRepository;
        PasswordEncoder passwordEncoder;
        IMailService mailService;
        IAuthenticationService authenticationService;

        @Override
        @Transactional(readOnly = true)
        public AdminAccountListResponse getAdmins(int page, int size, String search, String status,
                        String currentAdminId) {
                int safePage = Math.max(1, page);
                int safeSize = Math.min(Math.max(1, size), MAX_PAGE_SIZE);
                String searchParam = (search != null && !search.isBlank()) ? search.trim() : null;

                Pageable pageable = PageRequest.of(safePage - 1, safeSize, Sort.by(Sort.Direction.DESC, "createdAt"));
                // findStaffs nhận role làm tham số → tái sử dụng cho admin (positionId = null:
                // không lọc chức vụ)
                Page<User> adminPage = userRepository.findStaffs(
                                ERole.admin, parseStatusFilter(status), null, searchParam, pageable);

                List<AdminAccountResponse> content = adminPage.getContent().stream()
                                .map(u -> toResponse(u, currentAdminId))
                                .toList();

                PageResponse<AdminAccountResponse> pageResponse = PageResponse.<AdminAccountResponse>builder()
                                .currentPage(safePage)
                                .pageSize(safeSize)
                                .totalPages(adminPage.getTotalPages())
                                .totalElements(adminPage.getTotalElements())
                                .content(content)
                                .build();

                // Summary tính trên toàn bộ admin, không phụ thuộc filter
                AdminAccountSummaryResponse summary = AdminAccountSummaryResponse.builder()
                                .total(userRepository.countByRole(ERole.admin))
                                .active(userRepository.countByRoleAndStatus(ERole.admin, EUserStatus.active))
                                .blocked(userRepository.countByRoleAndStatus(ERole.admin, EUserStatus.blocked))
                                .build();

                return AdminAccountListResponse.builder()
                                .summary(summary)
                                .admins(pageResponse)
                                .build();
        }

        @Override
        @Transactional
        public AdminAccountResponse createAdmin(CreateAdminRequest request, String currentAdminId) {
                // 1. Validate email
                String email = request.email().trim();
                if (userRepository.existsByEmailAndRole(email, ERole.admin)) {
                        throw new BadRequestException("auth.email.exists");
                }

                // 2. Tự sinh mật khẩu, tạo tài khoản — password hash bằng BCrypt
                String rawPassword = PasswordGenerator.generateRandomPassword();
                String phone = (request.phone() != null && !request.phone().isBlank()) ? request.phone().trim() : null;
                User admin = User.builder()
                                .fullName(request.fullName().trim())
                                .email(email)
                                .phone(phone)
                                .password(passwordEncoder.encode(rawPassword))
                                .role(ERole.admin)
                                .status(EUserStatus.active)
                                .build();

                try {
                        // flush ngay để bắt vi phạm unique (email, role) khi tạo đồng thời — trước khi
                        // gửi mail
                        admin = userRepository.saveAndFlush(admin);
                } catch (DataIntegrityViolationException e) {
                        throw new BadRequestException("auth.email.exists");
                }

                // 3. Ghi Activity Log
                User actor = findUserOrNull(currentAdminId);
                logActivity(actor, "activity.admin.created|" + displayName(actor) + "|" + displayName(admin),
                                admin.getId());

                // 4. Gửi email thông tin đăng nhập. Lỗi → rollback, tài khoản không được tạo.
                try {
                        mailService.sendAdminCredentialsEmail(
                                        admin.getEmail(), admin.getFullName(), rawPassword, admin.getLanguage());
                } catch (MailException e) {
                        log.error("Failed to send admin credentials email to {}", admin.getEmail(), e);
                        throw new BadRequestException("mail.admin.credentials.send_failed");
                }

                return toResponse(admin, currentAdminId);
        }

        @Override
        @Transactional
        public void updateAdminStatus(String targetAdminId, UpdateAdminStatusRequest request, String currentAdminId) {
                EUserStatus newStatus = parseStatus(request.status());

                // 1. Không thao tác trên chính mình (tránh tự khóa)
                if (Objects.equals(targetAdminId, currentAdminId)) {
                        throw new BadRequestException("admin.account.cannot_lock_self");
                }

                // 2. Khi khóa: khóa ghi tất cả admin đang hoạt động TRƯỚC khi đọc target, để
                // các yêu cầu
                // khóa đồng thời được tuần tự hóa và luôn đọc trạng thái mới nhất.
                List<User> activeAdmins = newStatus == EUserStatus.blocked
                                ? userRepository.lockByRoleAndStatus(ERole.admin, EUserStatus.active)
                                : List.of();

                // Không lộ thông tin tài khoản staff/client qua API này → coi như không tồn tại
                User target = userRepository.findById(targetAdminId)
                                .filter(u -> u.getRole() == ERole.admin)
                                .orElseThrow(() -> new ResourceNotFoundException("admin.account.not_found"));

                if (target.getStatus() == newStatus) {
                        return; // idempotent: không đổi gì, không ghi log
                }

                if (newStatus == EUserStatus.blocked) {
                        // Người gọi có thể vừa bị khóa bởi một yêu cầu đồng thời đã commit trước
                        boolean callerStillActive = activeAdmins.stream()
                                        .anyMatch(u -> Objects.equals(u.getId(), currentAdminId));
                        if (!callerStillActive) {
                                throw new UnauthorizedException("auth.account.blocked");
                        }
                        // Phòng thủ: luôn phải còn ít nhất một admin hoạt động sau khi khóa
                        if (activeAdmins.size() <= 1) {
                                throw new BadRequestException("admin.account.last_active_admin");
                        }
                }

                target.setStatus(newStatus);
                userRepository.save(target);

                // 3. Khóa → thu hồi mọi phiên ngay lập tức; mở khóa → gỡ cờ chặn
                if (newStatus == EUserStatus.blocked) {
                        authenticationService.revokeUserAccess(target.getId());
                } else {
                        authenticationService.restoreUserAccess(target.getId());
                }

                // 4. Ghi Activity Log
                User actor = findUserOrNull(currentAdminId);
                logActivity(actor, "activity.admin.status_updated|" + displayName(actor) + "|" + displayName(target)
                                + "|" + newStatus.name(), target.getId());
        }

        // helpers

        private static EUserStatus parseStatusFilter(String status) {
                if (status == null || status.isBlank() || "all".equalsIgnoreCase(status.trim())) {
                        return null;
                }
                try {
                        return EUserStatus.valueOf(status.trim().toLowerCase());
                } catch (IllegalArgumentException e) {
                        return null;
                }
        }

        private static EUserStatus parseStatus(String status) {
                if (status == null || status.isBlank()) {
                        throw new BadRequestException("admin.account.status_invalid");
                }
                try {
                        return EUserStatus.valueOf(status.trim().toLowerCase());
                } catch (IllegalArgumentException e) {
                        throw new BadRequestException("admin.account.status_invalid");
                }
        }

        private AdminAccountResponse toResponse(User u, String currentAdminId) {
                return AdminAccountResponse.builder()
                                .id(u.getId())
                                .fullName(u.getFullName())
                                .email(u.getEmail())
                                .phoneNumber(u.getPhone())
                                .avatarUrl(u.getAvatarUrl())
                                .status(u.getStatus() != null ? u.getStatus().name() : null)
                                .createdAt(u.getCreatedAt())
                                .currentUser(u.getId() != null && u.getId().equals(currentAdminId))
                                .build();
        }

        private void logActivity(User actor, String i18nKey, String targetId) {
                activityHistoryRepository.save(ActivityHistory.builder()
                                .actor(actor)
                                .i18nKey(i18nKey)
                                .targetId(targetId)
                                .build());
        }

        private User findUserOrNull(String userId) {
                return userId != null ? userRepository.findById(userId).orElse(null) : null;
        }

        /**
         * Tên hiển thị dùng làm tham số i18n của activity; bỏ ký tự '|' vì đó là dấu
         * phân tách tham số.
         */
        private static String displayName(User user) {
                if (user == null) {
                        return "";
                }
                String name = (user.getFullName() != null && !user.getFullName().isBlank())
                                ? user.getFullName().trim()
                                : (user.getEmail() != null ? user.getEmail().trim() : "");
                return name.replace("|", " ");
        }
}
