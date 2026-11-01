package com.vn.smart_space.service.delegation;

import com.vn.smart_space.consts.EDelegationStatus;
import com.vn.smart_space.repository.ReportDelegationRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Hết hạn các yêu cầu nhờ làm giùm PENDING quá hạn và hoàn bonus cho người nhờ.
 * Mỗi yêu cầu chạy trong transaction riêng (gọi qua proxy của service) → một bản ghi lỗi không chặn cả lô.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class DelegationExpiryScheduler {

    static final int BATCH_SIZE = 100;

    ReportDelegationRepository delegationRepository;
    IReportDelegationService delegationService;

    @Scheduled(fixedDelay = 15 * 60 * 1000, initialDelay = 60 * 1000)
    public void expireOverdue() {
        List<String> ids = delegationRepository.findIdsByStatusAndExpiresAtBefore(
                EDelegationStatus.PENDING, LocalDateTime.now(), PageRequest.of(0, BATCH_SIZE));
        for (String id : ids) {
            try {
                delegationService.expire(id);
            } catch (Exception ex) {
                log.error("[Delegation] Failed to expire delegation {}: {}", id, ex.getMessage());
            }
        }
        if (!ids.isEmpty()) log.info("[Delegation] Expired {} overdue delegation request(s)", ids.size());
    }
}
