package com.vn.smart_space.service.autoassign;

import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import com.vn.smart_space.service.report.IReportService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Chạy bộ máy phân công (AUTO / ASSIST) cho phản ánh mới sau khi phản ánh đã được commit.
 * Việc phân công diễn ra trong transaction riêng (REQUIRES_NEW) có khoá phân công,
 * nên thất bại ở đây chỉ để phản ánh ở trạng thái chờ, không ảnh hưởng người dân.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ReportCreatedAutoAssignListener {

    private final IReportService reportService;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onReportCreated(ReportCreatedEvent event) {
        if (event == null || event.reportId() == null) {
            return;
        }
        try {
            reportService.autoAssignOnReportCreated(event.reportId());
        } catch (Exception e) {
            log.warn("[AutoAssign] Dispatch failed for report {}: {}", event.reportId(), e.getMessage());
        }
    }
}
