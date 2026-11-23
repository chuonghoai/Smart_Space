package com.vn.smart_space.service.admin;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Locale;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.support.ResourceBundleMessageSource;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class AdminHomeServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private ReportRepository reportRepository;
    @Mock
    private ActivityHistoryRepository activityHistoryRepository;

    private AdminHomeService adminHomeService;

    @BeforeEach
    void setUp() {
        ResourceBundleMessageSource messageSource = new ResourceBundleMessageSource();
        messageSource.setBasenames("i18n/messages");
        messageSource.setDefaultEncoding("UTF-8");
        messageSource.setFallbackToSystemLocale(false);

        adminHomeService = new AdminHomeService(
                userRepository,
                reportRepository,
                activityHistoryRepository,
                messageSource);
    }

    @Test
    void getPaginatedActivities_translatesCancelledAndUpdatedReportInViAndEn() {
        User actor = new User();
        actor.setId("u2");
        actor.setFullName("Trần Thị User");

        ActivityHistory cancelled = ActivityHistory.builder()
                .actor(actor)
                .i18nKey("activity.report.cancelled|Trần Thị User")
                .targetId("rep-1")
                .build();
        cancelled.setId("act-cancel");

        ActivityHistory bareCancelled = ActivityHistory.builder()
                .actor(actor)
                .i18nKey("activity.report.cancelled")
                .targetId("rep-2")
                .build();
        bareCancelled.setId("act-cancel-bare");

        ActivityHistory updated = ActivityHistory.builder()
                .actor(actor)
                .i18nKey("activity.report.updated|Trần Thị User")
                .targetId("rep-3")
                .build();
        updated.setId("act-upd");

        when(activityHistoryRepository.findActivitiesWithFilter(isNull(), isNull(), isNull(), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(cancelled, bareCancelled, updated)));

        var viPage = adminHomeService.getPaginatedActivities(1, 10, null, null, null, Locale.forLanguageTag("vi"));
        assertEquals("Trần Thị User đã hủy phản ánh", viPage.getContent().get(0).getMessage());
        assertEquals("REPORT", viPage.getContent().get(0).getTargetType());
        assertEquals("Trần Thị User đã hủy phản ánh", viPage.getContent().get(1).getMessage());
        assertEquals("Trần Thị User đã cập nhật phản ánh", viPage.getContent().get(2).getMessage());

        var enPage = adminHomeService.getPaginatedActivities(1, 10, null, null, null, Locale.ENGLISH);
        assertEquals("Trần Thị User cancelled a report", enPage.getContent().get(0).getMessage());
        assertEquals("Trần Thị User cancelled a report", enPage.getContent().get(1).getMessage());
        assertEquals("Trần Thị User updated a report", enPage.getContent().get(2).getMessage());

        // Unsupported locale falls back to vi rather than returning raw i18n key
        var fallbackPage = adminHomeService.getPaginatedActivities(1, 10, null, null, null, Locale.FRENCH);
        assertEquals("Trần Thị User đã hủy phản ánh", fallbackPage.getContent().get(0).getMessage());
    }
}
