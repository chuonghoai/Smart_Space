package com.vn.smart_space;

import com.vn.smart_space.configuration.ReportDeadlineSyncInitializer;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.repository.ConversationRepository;
import com.vn.smart_space.repository.ReportRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class SmartSpaceApplicationTests {

	@Autowired
	private ConversationRepository conversationRepository;

	@Autowired
	private ReportRepository reportRepository;

	@Autowired
	private ReportDeadlineSyncInitializer deadlineSyncInitializer;

	@Test
	void contextLoads() {
	}

	@Test
	void testSearchConversation() {
		var page = conversationRepository.findAllByUserIdAndQuery("u1", "nhân", PageRequest.of(0, 10));
		System.out.println("=== FOUND CONVERSATIONS FOR u1 with query 'nhân': " + page.getTotalElements() + " ===");
		for (var c : page.getContent()) {
			System.out.println("Conv: " + c.getId() + " - " + c.getLastMessageContent());
		}
	}

	@Test
	void overdueFilterIncludesProcessingAndLateCompletedReportsAfterDbSync() {
		deadlineSyncInitializer.syncMissingDeadlines();
		assertEquals(0, reportRepository.findByDeadlineIsNullAndStatusNot(EReportStatus.rejected).size());

		LocalDateTime now = LocalDateTime.now();
		Page<Report> adminOverdue = reportRepository.findAllFiltered(
				null, null, false, true, now, null, null, null, null, null, PageRequest.of(0, 100));
		assertTrue(adminOverdue.getTotalElements() > 0, "Expected synced DB to return overdue reports");
		assertTrue(
				adminOverdue.getContent().stream().anyMatch(r -> r.getStatus() == EReportStatus.processing),
				"Expected overdue filter to include active processing overdue reports");
		assertTrue(
				adminOverdue.getContent().stream().anyMatch(r -> r.getStatus() == EReportStatus.processed),
				"Expected overdue filter to include late-completed processed reports");

		String sampleOwnerId = adminOverdue.getContent().stream()
				.filter(r -> r.getUser() != null)
				.map(r -> r.getUser().getId())
				.findFirst()
				.orElse(null);
		if (sampleOwnerId != null) {
			Page<Report> clientOverdue = reportRepository.findMyReports(
					sampleOwnerId, null, null, false, true, now, null, null, null, PageRequest.of(0, 50));
			assertTrue(clientOverdue.getTotalElements() > 0, "Expected client overdue filter to return results");
		}

		String sampleStaffId = adminOverdue.getContent().stream()
				.filter(r -> r.getAssignedStaff() != null)
				.map(r -> r.getAssignedStaff().getId())
				.findFirst()
				.orElse(null);
		if (sampleStaffId != null) {
			List<Report> staffOverdue = reportRepository.findStaffAssignedFiltered(
					sampleStaffId,
					List.of(EReportStatus.processing, EReportStatus.processed),
					false,
					true,
					now,
					PageRequest.of(0, 50));
			assertFalse(staffOverdue.isEmpty(), "Expected staff overdue filter to return results");
		}
	}

}
