package com.vn.smart_space.service.admin;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.vn.smart_space.consts.EAccountLockRequestStatus;
import com.vn.smart_space.repository.AccountLockRequestRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

/**
 * Chuyển các đề xuất khóa tài khoản quá hạn biểu quyết sang expired.
 * Mỗi đề xuất chạy trong transaction riêng (gọi qua proxy của service) → một bản ghi lỗi không chặn cả lô.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AccountLockExpiryScheduler {

    static final int BATCH_SIZE = 100;

    AccountLockRequestRepository requestRepository;
    IAccountLockRequestService lockRequestService;

    @Scheduled(fixedDelay = 15 * 60 * 1000, initialDelay = 90 * 1000)
    public void expireOverdue() {
        List<String> ids = requestRepository.findIdsByStatusAndExpiresAtBefore(
                EAccountLockRequestStatus.pending, LocalDateTime.now(), PageRequest.of(0, BATCH_SIZE));
        for (String id : ids) {
            try {
                lockRequestService.expire(id);
            } catch (Exception ex) {
                log.error("[AccountLock] Failed to expire lock request {}: {}", id, ex.getMessage());
            }
        }
        if (!ids.isEmpty()) {
            log.info("[AccountLock] Expired {} overdue lock request(s)", ids.size());
        }
    }
}
