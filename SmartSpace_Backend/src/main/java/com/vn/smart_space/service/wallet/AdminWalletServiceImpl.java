package com.vn.smart_space.service.wallet;

import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EWalletTransactionType;
import com.vn.smart_space.consts.EWithdrawalStatus;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.request.wallet.ProcessWithdrawalRequest;
import com.vn.smart_space.dto.response.wallet.StaffWalletSummaryResponse;
import com.vn.smart_space.dto.response.wallet.StaffWalletTransactionResponse;
import com.vn.smart_space.dto.response.wallet.StaffWithdrawalRequestResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.model.StaffWallet;
import com.vn.smart_space.model.StaffWalletTransaction;
import com.vn.smart_space.model.StaffWithdrawalRequest;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.StaffWalletRepository;
import com.vn.smart_space.repository.StaffWalletTransactionRepository;
import com.vn.smart_space.repository.StaffWithdrawalRequestRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.notification.IFCMService;
import com.vn.smart_space.service.notification.INotificationService;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.MessageSource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminWalletServiceImpl implements IAdminWalletService {

    StaffWalletRepository staffWalletRepository;
    StaffWalletTransactionRepository staffWalletTransactionRepository;
    StaffWithdrawalRequestRepository staffWithdrawalRequestRepository;
    UserRepository userRepository;
    IStaffWalletService staffWalletService;
    IFCMService fcmService;
    INotificationService notificationService;
    MessageSource messageSource;

    @Override
    @Transactional(readOnly = true)
    public PageResponse<StaffWalletSummaryResponse> getStaffWallets(int page, int size, String search) {
        String searchParam = (search != null && !search.trim().isEmpty()) ? search.trim() : null;
        Pageable pageable = PageRequest.of(Math.max(0, page - 1), size);

        Page<User> staffPage = userRepository.findStaffs(ERole.staff, null, null, searchParam, pageable);
        List<User> staffUsers = staffPage.getContent();

        List<StaffWalletSummaryResponse> items = staffUsers.stream().map(u -> {
            StaffWallet wallet = staffWalletRepository.findByUserId(u.getId()).orElse(null);
            double balance = wallet != null ? wallet.getBalance() : 0.0;
            LocalDateTime updatedAt = wallet != null ? wallet.getUpdatedAt() : u.getUpdatedAt();

            return StaffWalletSummaryResponse.builder()
                    .id(wallet != null ? wallet.getId() : u.getId())
                    .userId(u.getId())
                    .fullName(u.getFullName())
                    .email(u.getEmail())
                    .phoneNumber(u.getPhone())
                    .avatarUrl(u.getAvatarUrl())
                    .balance(balance)
                    .updatedAt(updatedAt)
                    .build();
        }).collect(Collectors.toList());

        return PageResponse.<StaffWalletSummaryResponse>builder()
                .currentPage(page)
                .pageSize(size)
                .totalPages(staffPage.getTotalPages())
                .totalElements(staffPage.getTotalElements())
                .content(items)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public StaffWalletSummaryResponse getStaffWalletDetail(String staffId) {
        User staff = userRepository.findById(staffId)
                .orElseThrow(() -> new ResourceNotFoundException("staff.not_found"));

        StaffWallet wallet = staffWalletRepository.findByUserId(staff.getId()).orElse(null);
        double balance = wallet != null ? wallet.getBalance() : 0.0;
        LocalDateTime updatedAt = wallet != null ? wallet.getUpdatedAt() : staff.getUpdatedAt();

        return StaffWalletSummaryResponse.builder()
                .id(wallet != null ? wallet.getId() : staff.getId())
                .userId(staff.getId())
                .fullName(staff.getFullName())
                .email(staff.getEmail())
                .phoneNumber(staff.getPhone())
                .avatarUrl(staff.getAvatarUrl())
                .balance(balance)
                .updatedAt(updatedAt)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<StaffWalletTransactionResponse> getStaffTransactions(String staffId, int page, int size, Locale locale) {
        return staffWalletService.getTransactions(staffId, page, size, locale);
    }

    @Override
    @Transactional(readOnly = true)
    public long getPendingWithdrawalCount() {
        return staffWithdrawalRequestRepository.countByStatus(EWithdrawalStatus.PENDING);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<StaffWithdrawalRequestResponse> getWithdrawals(String status, int page, int size) {
        Pageable pageable = PageRequest.of(Math.max(0, page - 1), size);
        Page<StaffWithdrawalRequest> requestPage;

        if (status != null && !status.trim().isEmpty() && !status.equalsIgnoreCase("ALL")) {
            try {
                EWithdrawalStatus statusEnum = EWithdrawalStatus.valueOf(status.trim().toUpperCase());
                requestPage = staffWithdrawalRequestRepository.findByStatusOrderByCreatedAtDesc(statusEnum, pageable);
            } catch (IllegalArgumentException e) {
                requestPage = staffWithdrawalRequestRepository.findAllByOrderByCreatedAtDesc(pageable);
            }
        } else {
            requestPage = staffWithdrawalRequestRepository.findAllByOrderByCreatedAtDesc(pageable);
        }

        List<StaffWithdrawalRequestResponse> items = requestPage.getContent().stream()
                .map(this::mapToWithdrawalResponse)
                .collect(Collectors.toList());

        return PageResponse.<StaffWithdrawalRequestResponse>builder()
                .currentPage(page)
                .pageSize(size)
                .totalPages(requestPage.getTotalPages())
                .totalElements(requestPage.getTotalElements())
                .content(items)
                .build();
    }

    @Override
    @Transactional
    public StaffWithdrawalRequestResponse processWithdrawal(String id, ProcessWithdrawalRequest request, String adminId) {
        StaffWithdrawalRequest withdrawal = staffWithdrawalRequestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("wallet.withdrawal.not_found"));

        if (withdrawal.getStatus() != EWithdrawalStatus.PENDING) {
            throw new BadRequestException("wallet.withdrawal.already_processed");
        }

        User staff = withdrawal.getUser();
        Locale staffLocale = new Locale(staff.getLanguage() != null ? staff.getLanguage() : "vi");

        if ("APPROVED".equalsIgnoreCase(request.getStatus())) {
            StaffWallet wallet = staffWalletRepository.findByUserIdForUpdate(staff.getId())
                    .orElseGet(() -> staffWalletService.getOrCreateWallet(staff.getId()));

            if (wallet.getBalance() < withdrawal.getAmount()) {
                throw new BadRequestException("wallet.withdrawal.insufficient_balance");
            }

            double newBalance = wallet.getBalance() - withdrawal.getAmount();
            wallet.setBalance(newBalance);
            staffWalletRepository.save(wallet);

            StaffWalletTransaction transaction = StaffWalletTransaction.builder()
                    .wallet(wallet)
                    .type(EWalletTransactionType.WITHDRAWAL)
                    .amount(withdrawal.getAmount())
                    .balanceAfter(newBalance)
                    .titleI18nKey("wallet.transaction.withdrawal.title")
                    .titleParams(withdrawal.getBankName())
                    .build();
            staffWalletTransactionRepository.save(transaction);

            withdrawal.setStatus(EWithdrawalStatus.APPROVED);
            withdrawal.setAdminNote(request.getAdminNote());
            withdrawal.setProcessedAt(LocalDateTime.now());
            StaffWithdrawalRequest saved = staffWithdrawalRequestRepository.save(withdrawal);

            // Send Notification to Staff
            try {
                String title = messageSource.getMessage("notification.wallet.withdrawal.approved.title", null, "Yêu cầu rút tiền đã được duyệt", staffLocale);
                String msg = messageSource.getMessage("notification.wallet.withdrawal.approved.message",
                        new Object[]{String.format("%,.0f", withdrawal.getAmount()), withdrawal.getBankName()},
                        String.format("Yêu cầu rút %,.0fđ về tài khoản ngân hàng %s đã được xử lý thành công.", withdrawal.getAmount(), withdrawal.getBankName()),
                        staffLocale);

                NotificationRequest fcmRequest = new NotificationRequest(title, msg, Map.of("type", "STAFF_WALLET", "payload", "{}"));
                fcmService.sendToUser(staff.getId(), fcmRequest);
                notificationService.createNotification(staff.getId(), title, msg, "{\"type\": \"STAFF_WALLET\", \"payload\": {}}", null);
            } catch (Exception ex) {
                log.warn("[Staff Wallet] Failed to send withdrawal approved notification: {}", ex.getMessage());
            }

            return mapToWithdrawalResponse(saved);
        } else if ("REJECTED".equalsIgnoreCase(request.getStatus())) {
            withdrawal.setStatus(EWithdrawalStatus.REJECTED);
            withdrawal.setAdminNote(request.getAdminNote());
            withdrawal.setProcessedAt(LocalDateTime.now());
            StaffWithdrawalRequest saved = staffWithdrawalRequestRepository.save(withdrawal);

            // Send Notification to Staff
            try {
                String title = messageSource.getMessage("notification.wallet.withdrawal.rejected.title", null, "Yêu cầu rút tiền bị từ chối", staffLocale);
                String reason = request.getAdminNote() != null ? request.getAdminNote() : "";
                String msg = messageSource.getMessage("notification.wallet.withdrawal.rejected.message",
                        new Object[]{String.format("%,.0f", withdrawal.getAmount()), reason},
                        String.format("Yêu cầu rút %,.0fđ bị từ chối. Lý do: %s", withdrawal.getAmount(), reason),
                        staffLocale);

                NotificationRequest fcmRequest = new NotificationRequest(title, msg, Map.of("type", "STAFF_WALLET", "payload", "{}"));
                fcmService.sendToUser(staff.getId(), fcmRequest);
                notificationService.createNotification(staff.getId(), title, msg, "{\"type\": \"STAFF_WALLET\", \"payload\": {}}", null);
            } catch (Exception ex) {
                log.warn("[Staff Wallet] Failed to send withdrawal rejected notification: {}", ex.getMessage());
            }

            return mapToWithdrawalResponse(saved);
        } else {
            throw new BadRequestException("wallet.withdraw.status.required");
        }
    }

    private StaffWithdrawalRequestResponse mapToWithdrawalResponse(StaffWithdrawalRequest entity) {
        User u = entity.getUser();
        String qrUrl = generateVietQRUrl(entity.getBankCode(), entity.getBankAccountNumber(), entity.getAmount(), entity.getBankAccountName());

        return StaffWithdrawalRequestResponse.builder()
                .id(entity.getId())
                .userId(u != null ? u.getId() : null)
                .staffName(u != null ? u.getFullName() : "")
                .staffEmail(u != null ? u.getEmail() : "")
                .staffPhone(u != null ? u.getPhone() : "")
                .staffAvatar(u != null ? u.getAvatarUrl() : null)
                .amount(entity.getAmount())
                .bankCode(entity.getBankCode())
                .bankName(entity.getBankName())
                .bankAccountNumber(entity.getBankAccountNumber())
                .bankAccountName(entity.getBankAccountName())
                .qrCodeUrl(qrUrl)
                .status(entity.getStatus() != null ? entity.getStatus().name() : "")
                .note(entity.getNote())
                .adminNote(entity.getAdminNote())
                .createdAt(entity.getCreatedAt())
                .processedAt(entity.getProcessedAt())
                .build();
    }

    private String generateVietQRUrl(String bankCode, String accountNumber, Double amount, String accountName) {
        try {
            long amt = amount != null ? Math.round(amount) : 0L;
            String encodedAccountName = accountName != null ? URLEncoder.encode(accountName, StandardCharsets.UTF_8) : "";
            String encodedInfo = URLEncoder.encode("Rut tien vi SmartSpace", StandardCharsets.UTF_8);
            return String.format("https://img.vietqr.io/image/%s-%s-compact2.png?amount=%d&addInfo=%s&accountName=%s",
                    bankCode != null ? bankCode.trim() : "",
                    accountNumber != null ? accountNumber.trim() : "",
                    amt,
                    encodedInfo,
                    encodedAccountName);
        } catch (Exception e) {
            return "";
        }
    }
}
