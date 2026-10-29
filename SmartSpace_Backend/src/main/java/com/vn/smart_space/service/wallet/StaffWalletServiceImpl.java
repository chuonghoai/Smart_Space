package com.vn.smart_space.service.wallet;

import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EWalletTransactionType;
import com.vn.smart_space.consts.EWithdrawalStatus;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.request.wallet.CreateWithdrawalRequest;
import com.vn.smart_space.dto.response.report.ReportDetailResponse;
import com.vn.smart_space.dto.response.wallet.StaffWalletResponse;
import com.vn.smart_space.dto.response.wallet.StaffWalletTransactionResponse;
import com.vn.smart_space.dto.response.wallet.StaffWithdrawalRequestResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.StaffWallet;
import com.vn.smart_space.model.StaffWalletTransaction;
import com.vn.smart_space.model.StaffWithdrawalRequest;
import com.vn.smart_space.model.User;
import com.vn.smart_space.model.WalletConfig;
import com.vn.smart_space.repository.ReportRepository;
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
import org.springframework.messaging.simp.SimpMessagingTemplate;
import com.vn.smart_space.dto.response.notification.NotificationEvent;
import com.vn.smart_space.consts.ERole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
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
public class StaffWalletServiceImpl implements IStaffWalletService {

    StaffWalletRepository staffWalletRepository;
    StaffWalletTransactionRepository staffWalletTransactionRepository;
    StaffWithdrawalRequestRepository staffWithdrawalRequestRepository;
    UserRepository userRepository;
    ReportRepository reportRepository;
    IWalletConfigService walletConfigService;
    IFCMService fcmService;
    INotificationService notificationService;
    MessageSource messageSource;
    SimpMessagingTemplate messagingTemplate;

    @Override
    @Transactional
    public StaffWallet getOrCreateWallet(String userId) {
        return staffWalletRepository.findByUserId(userId).orElseGet(() -> {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new ResourceNotFoundException("user.not_found"));
            StaffWallet wallet = StaffWallet.builder()
                    .user(user)
                    .balance(0.0)
                    .build();
            return staffWalletRepository.save(wallet);
        });
    }

    @Override
    @Transactional
    public StaffWalletResponse getWalletResponse(String userId) {
        StaffWallet wallet = getOrCreateWallet(userId);
        return StaffWalletResponse.builder()
                .id(wallet.getId())
                .balance(wallet.getBalance())
                .userId(wallet.getUser() != null ? wallet.getUser().getId() : userId)
                .updatedAt(wallet.getUpdatedAt())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<StaffWalletTransactionResponse> getTransactions(String userId, int page, int size, Locale locale) {
        StaffWallet wallet = staffWalletRepository.findByUserId(userId)
                .orElse(null);

        if (wallet == null) {
            return PageResponse.<StaffWalletTransactionResponse>builder()
                    .currentPage(page)
                    .pageSize(size)
                    .totalElements(0)
                    .totalPages(0)
                    .content(List.of())
                    .build();
        }

        Page<StaffWalletTransaction> transactionPage = staffWalletTransactionRepository
                .findByWalletIdOrderByCreatedAtDesc(wallet.getId(), PageRequest.of(page, size));

        Locale activeLocale = locale != null ? locale : new Locale("vi");

        List<StaffWalletTransactionResponse> items = transactionPage.getContent().stream()
                .map(t -> {
                    String titleKey = t.getTitleI18nKey();
                    String title = null;
                    if (titleKey != null) {
                        try {
                            title = messageSource.getMessage(titleKey, null, titleKey, activeLocale);
                        } catch (Exception ignored) {
                            title = titleKey;
                        }
                    }
                    if (title == null || title.equals(titleKey)) {
                        if (t.getType() == EWalletTransactionType.COMMISSION) {
                            title = "Hoa hồng hoàn thành phản ánh";
                        } else if (t.getType() == EWalletTransactionType.PENALTY_DEDUCTION) {
                            title = "Phản ánh đánh giá xấu";
                        } else if (t.getType() == EWalletTransactionType.WITHDRAWAL_HOLD) {
                            title = "Tạm giữ yêu cầu rút tiền";
                        } else if (t.getType() == EWalletTransactionType.WITHDRAWAL_REFUND) {
                            title = "Hoàn tiền yêu cầu rút tiền";
                        } else {
                            title = "Rút tiền về tài khoản ngân hàng";
                        }
                    }

                    return StaffWalletTransactionResponse.builder()
                            .id(t.getId())
                            .type(t.getType() != null ? t.getType().name() : "")
                            .amount(t.getAmount())
                            .balanceAfter(t.getBalanceAfter())
                            .reportId(t.getReport() != null ? t.getReport().getId() : null)
                            .reportTitle(t.getReport() != null ? t.getReport().getTitle() : null)
                            .withdrawalId(t.getWithdrawalRequest() != null ? t.getWithdrawalRequest().getId() : null)
                            .titleI18nKey(t.getTitleI18nKey())
                            .titleParams(t.getTitleParams())
                            .title(title)
                            .createdAt(t.getCreatedAt())
                            .build();
                })
                .collect(Collectors.toList());

        return PageResponse.<StaffWalletTransactionResponse>builder()
                .currentPage(page)
                .pageSize(size)
                .totalElements(transactionPage.getTotalElements())
                .totalPages(transactionPage.getTotalPages())
                .content(items)
                .build();
    }

    @Override
    @Transactional
    public void processReportCompletedCommission(Report report) {
        if (report == null || report.getAssignedStaff() == null) {
            return;
        }

        // Idempotency: Check if commission has already been awarded
        if (Boolean.TRUE.equals(report.getCommissionAwarded())) {
            log.info("[Staff Wallet] Report {} has already been awarded commission. Skipping.", report.getId());
            return;
        }

        User staff = report.getAssignedStaff();
        WalletConfig config = walletConfigService.getOrCreateDefaultConfig();

        double commission = getCommissionAmountBySeverity(report.getSeverity(), config);

        StaffWallet wallet = staffWalletRepository.findByUserIdForUpdate(staff.getId())
                .orElseGet(() -> {
                    StaffWallet newWallet = StaffWallet.builder()
                            .user(staff)
                            .balance(0.0)
                            .build();
                    return staffWalletRepository.save(newWallet);
                });

        double newBalance = wallet.getBalance() + commission;
        wallet.setBalance(newBalance);
        staffWalletRepository.save(wallet);

        StaffWalletTransaction transaction = StaffWalletTransaction.builder()
                .wallet(wallet)
                .type(EWalletTransactionType.COMMISSION)
                .amount(commission)
                .balanceAfter(newBalance)
                .report(report)
                .titleI18nKey("wallet.transaction.commission.title")
                .titleParams(report.getTitle())
                .build();
        staffWalletTransactionRepository.save(transaction);

        // Update report state
        report.setBaseCommission(commission);
        report.setTotalCommissionDeducted(0.0);
        report.setRehandlingPenaltyCount(0);
        report.setCommissionAwarded(true);
        reportRepository.save(report);

        // Send FCM Notification to staff
        try {
            Locale staffLocale = new Locale(staff.getLanguage() != null ? staff.getLanguage() : "vi");
            String title = messageSource.getMessage(
                    "notification.wallet.commission.title",
                    null,
                    "Nhận hoa hồng phản ánh",
                    staffLocale);
            String message = messageSource.getMessage(
                    "notification.wallet.commission.message",
                    new Object[]{ String.format("%,.0f", commission), report.getTitle() != null ? report.getTitle() : "" },
                    String.format("Bạn đã nhận được %,.0fđ hoa hồng khi hoàn thành phản ánh '%s'.", commission, report.getTitle()),
                    staffLocale);

            NotificationRequest fcmRequest = new NotificationRequest(
                    title,
                    message,
                    Map.of("type", "STAFF_WALLET", "payload", "{}"));
            fcmService.sendToUser(staff.getId(), fcmRequest);

            notificationService.createNotification(
                    staff.getId(),
                    title,
                    message,
                    "{\"type\": \"STAFF_WALLET\", \"payload\": {}}",
                    report.getImageUrl());
        } catch (Exception ex) {
            log.warn("[Staff Wallet] Failed to send commission notification to staff {}: {}", staff.getId(), ex.getMessage());
        }
    }

    @Override
    @Transactional
    public void processReportReopenPenalty(Report report) {
        if (report == null || report.getAssignedStaff() == null) {
            return;
        }

        // Only penalize if initial commission was awarded
        if (!Boolean.TRUE.equals(report.getCommissionAwarded()) || report.getBaseCommission() == null) {
            log.info("[Staff Wallet] Report {} has no base commission awarded. Skipping penalty.", report.getId());
            return;
        }

        int penaltyCount = report.getRehandlingPenaltyCount() != null ? report.getRehandlingPenaltyCount() : 0;
        if (penaltyCount >= 3) {
            log.info("[Staff Wallet] Report {} has reached maximum penalty turns (3). Skipping penalty.", report.getId());
            return;
        }

        User staff = report.getAssignedStaff();
        WalletConfig config = walletConfigService.getOrCreateDefaultConfig();

        double penaltyRate = switch (penaltyCount) {
            case 0 -> config.getPenaltyRate1(); // Turn 1: 20%
            case 1 -> config.getPenaltyRate2(); // Turn 2: 20%
            case 2 -> config.getPenaltyRate3(); // Turn 3: 60%
            default -> 0.0;
        };

        double penaltyAmount = report.getBaseCommission() * (penaltyRate / 100.0);

        StaffWallet wallet = staffWalletRepository.findByUserIdForUpdate(staff.getId())
                .orElseGet(() -> {
                    StaffWallet newWallet = StaffWallet.builder()
                            .user(staff)
                            .balance(0.0)
                            .build();
                    return staffWalletRepository.save(newWallet);
                });

        double newBalance = Math.max(0.0, wallet.getBalance() - penaltyAmount);
        wallet.setBalance(newBalance);
        staffWalletRepository.save(wallet);

        StaffWalletTransaction transaction = StaffWalletTransaction.builder()
                .wallet(wallet)
                .type(EWalletTransactionType.PENALTY_DEDUCTION)
                .amount(penaltyAmount)
                .balanceAfter(newBalance)
                .report(report)
                .titleI18nKey("wallet.transaction.penalty.title")
                .titleParams(report.getTitle())
                .build();
        staffWalletTransactionRepository.save(transaction);

        // Update report penalty tracking
        report.setRehandlingPenaltyCount(penaltyCount + 1);
        double totalDeducted = report.getTotalCommissionDeducted() != null ? report.getTotalCommissionDeducted() : 0.0;
        report.setTotalCommissionDeducted(totalDeducted + penaltyAmount);
        reportRepository.save(report);

        // Send FCM Notification to staff
        try {
            Locale staffLocale = new Locale(staff.getLanguage() != null ? staff.getLanguage() : "vi");
            String title = messageSource.getMessage(
                    "notification.wallet.penalty.title",
                    null,
                    "Trừ hoa hồng phản ánh",
                    staffLocale);
            String message = messageSource.getMessage(
                    "notification.wallet.penalty.message",
                    new Object[]{ report.getTitle() != null ? report.getTitle() : "", String.format("%,.0f", penaltyAmount) },
                    String.format("Phản ánh '%s' bị đánh giá xấu và yêu cầu xử lý lại. Hoa hồng bị trừ %,.0fđ.", report.getTitle(), penaltyAmount),
                    staffLocale);

            NotificationRequest fcmRequest = new NotificationRequest(
                    title,
                    message,
                    Map.of("type", "STAFF_WALLET", "payload", "{}"));
            fcmService.sendToUser(staff.getId(), fcmRequest);

            notificationService.createNotification(
                    staff.getId(),
                    title,
                    message,
                    "{\"type\": \"STAFF_WALLET\", \"payload\": {}}",
                    report.getImageUrl());
        } catch (Exception ex) {
            log.warn("[Staff Wallet] Failed to send penalty notification to staff {}: {}", staff.getId(), ex.getMessage());
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<ReportDetailResponse.PenaltyDeductionItem> getPenaltyDeductionsForReport(Report report) {
        if (report == null) return java.util.Collections.emptyList();

        List<StaffWalletTransaction> penaltyTransactions = staffWalletTransactionRepository
                .findByReportIdAndType(report.getId(), EWalletTransactionType.PENALTY_DEDUCTION);

        if (!penaltyTransactions.isEmpty()) {
            List<ReportDetailResponse.PenaltyDeductionItem> items = new java.util.ArrayList<>();
            for (int i = 0; i < penaltyTransactions.size(); i++) {
                StaffWalletTransaction tx = penaltyTransactions.get(i);
                items.add(ReportDetailResponse.PenaltyDeductionItem.builder()
                        .turn(i + 1)
                        .amount(tx.getAmount())
                        .build());
            }
            return items;
        }

        int count = report.getRehandlingPenaltyCount() != null ? report.getRehandlingPenaltyCount() : 0;
        if (count > 0 && report.getBaseCommission() != null) {
            WalletConfig config = walletConfigService.getOrCreateDefaultConfig();
            double base = report.getBaseCommission();
            List<ReportDetailResponse.PenaltyDeductionItem> items = new java.util.ArrayList<>();
            for (int i = 0; i < Math.min(count, 3); i++) {
                double rate = switch (i) {
                    case 0 -> config.getPenaltyRate1() != null ? config.getPenaltyRate1() : 20.0;
                    case 1 -> config.getPenaltyRate2() != null ? config.getPenaltyRate2() : 20.0;
                    case 2 -> config.getPenaltyRate3() != null ? config.getPenaltyRate3() : 60.0;
                    default -> 0.0;
                };
                items.add(ReportDetailResponse.PenaltyDeductionItem.builder()
                        .turn(i + 1)
                        .amount(base * (rate / 100.0))
                        .build());
            }
            return items;
        }

        return java.util.Collections.emptyList();
    }

    @Override
    @Transactional
    public StaffWithdrawalRequestResponse createWithdrawalRequest(String userId, CreateWithdrawalRequest request) {
        User staff = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("user.not_found"));

        StaffWallet wallet = getOrCreateWallet(userId);
        if (wallet.getBalance() < request.getAmount()) {
            throw new BadRequestException("wallet.withdrawal.insufficient_balance");
        }

        double newBalance = wallet.getBalance() - request.getAmount();
        wallet.setBalance(newBalance);
        staffWalletRepository.save(wallet);

        StaffWithdrawalRequest withdrawal = StaffWithdrawalRequest.builder()
                .user(staff)
                .amount(request.getAmount())
                .bankCode(request.getBankCode())
                .bankName(request.getBankName())
                .bankAccountNumber(request.getBankAccountNumber())
                .bankAccountName(request.getBankAccountName())
                .status(EWithdrawalStatus.PENDING)
                .note(request.getNote())
                .build();

        StaffWithdrawalRequest saved = staffWithdrawalRequestRepository.save(withdrawal);

        StaffWalletTransaction holdTx = StaffWalletTransaction.builder()
                .wallet(wallet)
                .type(EWalletTransactionType.WITHDRAWAL_HOLD)
                .amount(request.getAmount())
                .balanceAfter(newBalance)
                .withdrawalRequest(saved)
                .titleI18nKey("wallet.transaction.withdrawal_hold.title")
                .titleParams(request.getBankName())
                .build();
        staffWalletTransactionRepository.save(holdTx);

        // Notify Admins about new withdrawal request
        try {
            List<User> admins = userRepository.findByRole(ERole.admin);
            String adminActionData = "{\"type\": \"ADMIN_WITHDRAWAL_REQUEST\", \"payload\": {\"withdrawalId\": \"" + saved.getId() + "\"}}";

            for (User admin : admins) {
                try {
                    Locale adminLocale = "en".equalsIgnoreCase(admin.getLanguage()) ? Locale.ENGLISH : Locale.forLanguageTag("vi");
                    String defaultStaffName = messageSource.getMessage("common.staff", null, "Nhân viên", adminLocale);
                    String staffName = (staff.getFullName() != null && !staff.getFullName().isBlank()) ? staff.getFullName() : defaultStaffName;

                    String adminTitle = messageSource.getMessage("notification.wallet.withdrawal.created.title", null, "Yêu cầu rút tiền mới", adminLocale);
                    String adminMessage = messageSource.getMessage("notification.wallet.withdrawal.created.message",
                            new Object[]{staffName},
                            String.format("Có yêu cầu rút tiền mới của %s", staffName),
                            adminLocale);

                    NotificationEvent adminEvent = new NotificationEvent(adminTitle, adminMessage, adminActionData, null, Map.of("shouldRefresh", true));
                    NotificationRequest adminFcm = new NotificationRequest(adminTitle, adminMessage, Map.of("type", "ADMIN_WITHDRAWAL_REQUEST", "payload", "{\"withdrawalId\":\"" + saved.getId() + "\"}"));

                    notificationService.createNotification(admin.getId(), adminTitle, adminMessage, adminActionData, null);
                    messagingTemplate.convertAndSendToUser(admin.getId(), "/queue/notifications", adminEvent);
                    fcmService.sendToUser(admin.getId(), adminFcm);
                } catch (Exception ex) {
                    log.warn("[Staff Wallet] Failed to notify admin {}: {}", admin.getId(), ex.getMessage());
                }
            }
        } catch (Exception ex) {
            log.warn("[Staff Wallet] Error while notifying admins of new withdrawal: {}", ex.getMessage());
        }

        return mapToWithdrawalResponse(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public List<StaffWithdrawalRequestResponse> getMyWithdrawals(String userId) {
        List<StaffWithdrawalRequest> list = staffWithdrawalRequestRepository.findByUserIdOrderByCreatedAtDesc(userId);
        return list.stream().map(this::mapToWithdrawalResponse).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public StaffWithdrawalRequestResponse cancelWithdrawalRequest(String userId, String withdrawalId) {
        if (userId == null || withdrawalId == null) {
            throw new BadRequestException("wallet.withdrawal.not_found");
        }

        StaffWithdrawalRequest withdrawal = staffWithdrawalRequestRepository.findById(withdrawalId)
                .orElseThrow(() -> new BadRequestException("wallet.withdrawal.not_found"));

        User staff = withdrawal.getUser();
        if (staff == null || !userId.equals(staff.getId())) {
            throw new BadRequestException("wallet.withdrawal.unauthorized");
        }

        if (withdrawal.getStatus() != EWithdrawalStatus.PENDING) {
            throw new BadRequestException("wallet.withdrawal.already_processed");
        }

        // 1. Hoàn lại số dư ví nhân viên
        StaffWallet wallet = staffWalletRepository.findByUserIdForUpdate(userId)
                .orElseGet(() -> getOrCreateWallet(userId));

        double refundBalance = wallet.getBalance() + withdrawal.getAmount();
        wallet.setBalance(refundBalance);
        staffWalletRepository.save(wallet);

        // 2. Ghi nhận giao dịch hoàn tiền WITHDRAWAL_REFUND
        StaffWalletTransaction refundTrans = StaffWalletTransaction.builder()
                .wallet(wallet)
                .type(EWalletTransactionType.WITHDRAWAL_REFUND)
                .amount(withdrawal.getAmount())
                .balanceAfter(refundBalance)
                .withdrawalRequest(withdrawal)
                .titleI18nKey("wallet.transaction.withdrawal_cancel.title")
                .titleParams(withdrawal.getBankName())
                .build();
        staffWalletTransactionRepository.save(refundTrans);

        // 3. Cập nhật trạng thái StaffWithdrawalRequest -> CANCELLED
        withdrawal.setStatus(EWithdrawalStatus.CANCELLED);
        Locale staffLocale = "en".equalsIgnoreCase(staff.getLanguage()) ? Locale.ENGLISH : Locale.forLanguageTag("vi");
        String cancelNote = messageSource.getMessage("wallet.withdrawal.cancelled.note", null, "Nhân viên tự hủy yêu cầu", staffLocale);
        withdrawal.setAdminNote(cancelNote);
        withdrawal.setProcessedAt(LocalDateTime.now());
        StaffWithdrawalRequest saved = staffWithdrawalRequestRepository.save(withdrawal);

        // 4. Bắn Notification cho nhân viên (Staff)
        try {
            String title = messageSource.getMessage("notification.wallet.withdrawal.cancelled.title", null, "Yêu cầu rút tiền đã được hủy", staffLocale);
            String msg = messageSource.getMessage("notification.wallet.withdrawal.cancelled.message",
                    new Object[]{ String.format("%,.0f", withdrawal.getAmount()), withdrawal.getBankName() },
                    String.format("Yêu cầu rút %,.0fđ về tài khoản ngân hàng %s đã được hủy thành công. Số tiền tạm giữ đã được hoàn lại vào ví.", withdrawal.getAmount(), withdrawal.getBankName()),
                    staffLocale);

            String actionData = "{\"type\": \"STAFF_WITHDRAWAL\", \"payload\": {\"status\": \"CANCELLED\", \"withdrawalId\": \"" + saved.getId() + "\"}}";
            NotificationEvent event = new NotificationEvent(title, msg, actionData, null, Map.of("shouldRefresh", true));
            NotificationRequest fcmRequest = new NotificationRequest(title, msg, Map.of("type", "STAFF_WITHDRAWAL", "payload", "{\"status\":\"CANCELLED\",\"withdrawalId\":\"" + saved.getId() + "\"}"));

            fcmService.sendToUser(staff.getId(), fcmRequest);
            messagingTemplate.convertAndSendToUser(staff.getId(), "/queue/notifications", event);
            notificationService.createNotification(staff.getId(), title, msg, actionData, null);
        } catch (Exception ex) {
            log.warn("[Staff Wallet] Failed to send withdrawal cancelled notification to staff {}: {}", staff.getId(), ex.getMessage());
        }

        // 5. Bắn WebSocket Event, FCM và tạo Notification cho Admin để đồng bộ danh sách realtime
        try {
            List<User> admins = userRepository.findByRole(ERole.admin);
            String adminActionData = "{\"type\": \"ADMIN_WITHDRAWAL_REQUEST\", \"payload\": {\"status\": \"CANCELLED\", \"withdrawalId\": \"" + saved.getId() + "\"}}";

            for (User admin : admins) {
                try {
                    Locale adminLocale = "en".equalsIgnoreCase(admin.getLanguage()) ? Locale.ENGLISH : Locale.forLanguageTag("vi");
                    String defaultStaffName = messageSource.getMessage("common.staff", null, "Nhân viên", adminLocale);
                    String staffDisplayName = (staff.getFullName() != null && !staff.getFullName().isBlank()) ? staff.getFullName() : defaultStaffName;

                    String adminTitle = messageSource.getMessage(
                            "notification.wallet.withdrawal.cancelled.admin.title",
                            null,
                            "Yêu cầu rút tiền đã bị hủy",
                            adminLocale);

                    String adminMsg = messageSource.getMessage(
                            "notification.wallet.withdrawal.cancelled.admin.message",
                            new Object[]{ staffDisplayName, String.format("%,.0f", withdrawal.getAmount()) },
                            String.format("%s đã hủy yêu cầu rút tiền %,.0fđ.", staffDisplayName, withdrawal.getAmount()),
                            adminLocale);

                    NotificationEvent adminEvent = new NotificationEvent(
                            adminTitle,
                            adminMsg,
                            adminActionData,
                            null,
                            Map.of("shouldRefresh", true, "status", "CANCELLED", "withdrawalId", saved.getId()));

                    NotificationRequest adminFcm = new NotificationRequest(
                            adminTitle,
                            adminMsg,
                            Map.of("type", "ADMIN_WITHDRAWAL_REQUEST", "payload", "{\"status\":\"CANCELLED\",\"withdrawalId\":\"" + saved.getId() + "\"}"));

                    notificationService.createNotification(admin.getId(), adminTitle, adminMsg, adminActionData, null);
                    messagingTemplate.convertAndSendToUser(admin.getId(), "/queue/notifications", adminEvent);
                    fcmService.sendToUser(admin.getId(), adminFcm);
                } catch (Exception ex) {
                    log.warn("[Staff Wallet] Failed to notify admin {} about cancelled withdrawal: {}", admin.getId(), ex.getMessage());
                }
            }
        } catch (Exception ex) {
            log.warn("[Staff Wallet] Failed to notify admins about cancelled withdrawal: {}", ex.getMessage());
        }

        return mapToWithdrawalResponse(saved);
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

    private double getCommissionAmountBySeverity(EReportSeverity severity, WalletConfig config) {
        if (severity == null) {
            return config.getCommissionLow();
        }
        return switch (severity) {
            case low -> config.getCommissionLow();
            case medium -> config.getCommissionMedium();
            case high -> config.getCommissionHigh();
            case critical -> config.getCommissionCritical();
        };
    }
}
