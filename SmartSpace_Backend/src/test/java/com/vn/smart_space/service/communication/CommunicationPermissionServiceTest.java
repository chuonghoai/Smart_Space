package com.vn.smart_space.service.communication;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.vn.smart_space.consts.EConversationType;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.model.Conversation;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ConversationRepository;
import com.vn.smart_space.repository.ReportRepository;

@ExtendWith(MockitoExtension.class)
class CommunicationPermissionServiceTest {

    @Mock
    private ReportRepository reportRepository;
    @Mock
    private ConversationRepository conversationRepository;

    @InjectMocks
    private CommunicationPermissionService service;

    private User user(String id, ERole role) {
        User u = User.builder()
                .email(id + "@test.local")
                .role(role)
                .status(EUserStatus.active)
                .build();
        u.setId(id);
        return u;
    }

    private Report report(String id, User client, User staff, EReportStatus status, Boolean isReviewResolved, Boolean isAnon) {
        Report r = Report.builder()
                .title("Report " + id)
                .user(client)
                .assignedStaff(staff)
                .status(status)
                .isReviewResolved(isReviewResolved)
                .isAnonymous(isAnon)
                .build();
        r.setId(id);
        return r;
    }

    private Conversation privateConv(String id, User u1, User u2, boolean isAnon, String hash) {
        Conversation c = Conversation.builder()
                .id(id)
                .conversationType(EConversationType.PRIVATE)
                .isAnonymous(isAnon)
                .participantHash(hash)
                .build();
        c.addParticipants(u1);
        c.addParticipants(u2);
        return c;
    }

    @Nested
    @DisplayName("Call & Chat Permission Matrix (Section 13)")
    class PermissionMatrixTests {

        @Test
        @DisplayName("Case 1: Client -> Client is completely forbidden")
        void clientToClientDenied() {
            User c1 = user("c1", ERole.client);
            User c2 = user("c2", ERole.client);

            CommunicationEligibility res = service.evaluatePairEligibility(c1, c2, null, null);
            assertFalse(res.canVoiceCall());
            assertFalse(res.canMessage());
            assertEquals("conversation.client_client_forbidden", res.reasonCode());
        }

        @Test
        @DisplayName("Case 2 & 4 & 5: Client <-> Staff denied when no active/processing report or conversation locked")
        void clientStaffDeniedWhenLocked() {
            User c1 = user("c1", ERole.client);
            User s1 = user("s1", ERole.staff);
            Conversation lockedConv = privateConv("conv1", c1, s1, false, "user_c1_s1");

            when(conversationRepository.findByIdAndMember("conv1", "c1")).thenReturn(Optional.of(lockedConv));
            when(reportRepository.findActiveReportsByConversationId("conv1")).thenReturn(List.of());
            when(reportRepository.findActiveReportsByClientAndStaffAndAnonymous("c1", "s1", false)).thenReturn(List.of());

            CommunicationEligibility res = service.evaluatePairEligibility(c1, s1, "conv1", null);
            assertFalse(res.canVoiceCall());
            assertFalse(res.canMessage());
            assertEquals("chat.report.not_processing", res.reasonCode());
        }

        @Test
        @DisplayName("Case 3: Client <-> Staff allowed when unlocked with processing report (even anonymous)")
        void clientStaffAllowedWhenProcessingIncludingAnonymous() {
            User c1 = user("c1", ERole.client);
            User s1 = user("s1", ERole.staff);
            Conversation anonConv = privateConv("convAnon", c1, s1, true, "anon_c1_s1");
            Report r = report("r1", c1, s1, EReportStatus.processing, null, true);

            when(conversationRepository.findByIdAndMember("convAnon", "s1")).thenReturn(Optional.of(anonConv));
            when(reportRepository.findActiveReportsByConversationId("convAnon")).thenReturn(List.of(r));

            CommunicationEligibility res = service.evaluatePairEligibility(s1, c1, "convAnon", null);
            assertTrue(res.canVoiceCall());
            assertTrue(res.canMessage());
            assertTrue(res.isAnonymous());
        }

        @Test
        @DisplayName("Case 6: Staff <-> Staff always allowed without Report")
        void staffToStaffAllowed() {
            User s1 = user("s1", ERole.staff);
            User s2 = user("s2", ERole.staff);

            CommunicationEligibility res = service.evaluatePairEligibility(s1, s2, null, null);
            assertTrue(res.canVoiceCall());
            assertTrue(res.canMessage());
            assertFalse(res.isAnonymous());
        }

        @Test
        @DisplayName("Case 7 & 8: Staff <-> Admin always allowed without Report")
        void staffAdminAllowedBothDirections() {
            User s1 = user("s1", ERole.staff);
            User a1 = user("a1", ERole.admin);

            assertTrue(service.evaluatePairEligibility(s1, a1, null, null).canVoiceCall());
            assertTrue(service.evaluatePairEligibility(a1, s1, null, null).canVoiceCall());
        }

        @Test
        @DisplayName("Case 9: Admin <-> Client denied when no rehandling processing report exists")
        void adminClientDeniedWithoutRehandlingProcessing() {
            User a1 = user("a1", ERole.admin);
            User c1 = user("c1", ERole.client);

            when(reportRepository.countAdminRehandlingProcessingReportsByClient("c1", false)).thenReturn(0L);
            when(reportRepository.countAdminRehandlingProcessingReportsByClient("c1", true)).thenReturn(0L);

            CommunicationEligibility res = service.evaluatePairEligibility(a1, c1, null, null);
            assertFalse(res.canVoiceCall());
            assertFalse(res.canMessage());
            assertEquals("conversation.admin_client_rehandling_required", res.reasonCode());
        }

        @Test
        @DisplayName("Case 10: Admin <-> Client allowed when at least one rehandling report is processing")
        void adminClientAllowedWhenRehandlingProcessingExists() {
            User a1 = user("a1", ERole.admin);
            User c1 = user("c1", ERole.client);

            when(reportRepository.countAdminRehandlingProcessingReportsByClient("c1", false)).thenReturn(1L);
            when(reportRepository.countAdminRehandlingProcessingReportsByClient("c1", true)).thenReturn(0L);

            CommunicationEligibility res = service.evaluatePairEligibility(a1, c1, null, null);
            assertTrue(res.canVoiceCall());
            assertTrue(res.canMessage());
            assertFalse(res.isAnonymous());
            assertEquals(1L, res.eligibleRehandlingReportCount());
        }

        @Test
        @DisplayName("Admin <-> Client anonymous-only rehandling report preserves anonymity mask")
        void adminClientAnonymousOnlyMasked() {
            User a1 = user("a1", ERole.admin);
            User c1 = user("c1", ERole.client);

            when(reportRepository.countAdminRehandlingProcessingReportsByClient("c1", false)).thenReturn(0L);
            when(reportRepository.countAdminRehandlingProcessingReportsByClient("c1", true)).thenReturn(1L);

            CommunicationEligibility res = service.evaluatePairEligibility(a1, c1, null, null);
            assertTrue(res.canVoiceCall());
            assertTrue(res.canMessage());
            assertTrue(res.isAnonymous());
        }
    }

    @Nested
    @DisplayName("Admin <-> Client Attachment Security (Section 15)")
    class AttachmentSecurityTests {

        @Test
        @DisplayName("Rejects attaching a report belonging to a DIFFERENT client")
        void rejectsOtherClientReport() {
            User admin = user("a1", ERole.admin);
            User c1 = user("c1", ERole.client);
            User c2 = user("c2", ERole.client);
            Conversation conv = privateConv("convAC", admin, c1, false, "admin_user_a1_c1");
            Report foreignReport = report("rForeign", c2, null, EReportStatus.processing, false, false);

            when(reportRepository.findById("rForeign")).thenReturn(Optional.of(foreignReport));

            assertThrows(BadRequestException.class, () ->
                    service.validateAndResolveAttachableReports(admin, conv, List.of("rForeign")));
        }

        @Test
        @DisplayName("Rejects attaching a processing report that is NOT marked rehandling (isReviewResolved != false)")
        void rejectsNonRehandlingProcessingReportInAdminClientChat() {
            User admin = user("a1", ERole.admin);
            User c1 = user("c1", ERole.client);
            Conversation conv = privateConv("convAC", admin, c1, false, "admin_user_a1_c1");
            Report normalProcessing = report("rNorm", c1, null, EReportStatus.processing, null, false);

            when(reportRepository.findById("rNorm")).thenReturn(Optional.of(normalProcessing));

            assertThrows(BadRequestException.class, () ->
                    service.validateAndResolveAttachableReports(admin, conv, List.of("rNorm")));
        }

        @Test
        @DisplayName("Rejects attaching a processed report even if isReviewResolved == false (must be reopened to processing)")
        void rejectsProcessedUnresolvedReportInAdminClientChat() {
            User admin = user("a1", ERole.admin);
            User c1 = user("c1", ERole.client);
            Conversation conv = privateConv("convAC", admin, c1, false, "admin_user_a1_c1");
            Report processedUnresolved = report("rWait", c1, null, EReportStatus.processed, false, false);

            when(reportRepository.findById("rWait")).thenReturn(Optional.of(processedUnresolved));

            assertThrows(BadRequestException.class, () ->
                    service.validateAndResolveAttachableReports(admin, conv, List.of("rWait")));
        }

        @Test
        @DisplayName("Allows attaching valid rehandling + processing reports belonging to the conversation client")
        void allowsValidRehandlingProcessingReports() {
            User admin = user("a1", ERole.admin);
            User c1 = user("c1", ERole.client);
            Conversation conv = privateConv("convAC", admin, c1, false, "admin_user_a1_c1");
            Report valid = report("rValid", c1, null, EReportStatus.processing, false, false);

            when(reportRepository.findById("rValid")).thenReturn(Optional.of(valid));

            List<Report> resolved = service.validateAndResolveAttachableReports(admin, conv, List.of("rValid", "rValid"));
            assertEquals(1, resolved.size());
            assertEquals("rValid", resolved.get(0).getId());
        }
    }
}
