package com.vn.smart_space.configuration;

import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.service.report.ReportServiceImpl;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Đảm bảo mọi phản ánh không bị từ chối trong DB đều có giá trị `deadline` đồng bộ
 * với `ReportServiceImpl.resolveDeadline`, giúp bộ lọc quá hạn hoạt động chính xác.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ReportDeadlineSyncInitializer implements ApplicationRunner {

    private final ReportRepository reportRepository;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        int updated = syncMissingDeadlines();
        if (updated > 0) {
            log.info("[DeadlineSync] Backfilled deadline for {} legacy report(s).", updated);
        }
    }

    public int syncMissingDeadlines() {
        List<Report> missing = reportRepository.findByDeadlineIsNullAndStatusNot(EReportStatus.rejected);
        if (missing.isEmpty()) {
            return 0;
        }
        List<Report> toSave = new ArrayList<>();
        for (Report report : missing) {
            LocalDateTime resolvedDeadline = ReportServiceImpl.resolveDeadline(report);
            if (resolvedDeadline != null) {
                report.setDeadline(resolvedDeadline);
                toSave.add(report);
            }
        }
        if (toSave.isEmpty()) {
            return 0;
        }
        reportRepository.saveAll(toSave);
        return toSave.size();
    }
}
