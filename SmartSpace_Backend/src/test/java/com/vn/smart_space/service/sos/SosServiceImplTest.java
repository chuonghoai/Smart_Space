package com.vn.smart_space.service.sos;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import com.vn.smart_space.consts.EEmergencyContactConsent;
import com.vn.smart_space.consts.EEmergencyContactStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.ESosResolution;
import com.vn.smart_space.consts.ESosStatus;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.request.sos.ResolveSosRequest;
import com.vn.smart_space.dto.request.sos.SosLocationRequest;
import com.vn.smart_space.dto.request.sos.StartSosRequest;
import com.vn.smart_space.dto.response.sos.SosAlertResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.model.EmergencyContact;
import com.vn.smart_space.model.SosAlert;
import com.vn.smart_space.model.SosLocationPoint;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.EmergencyContactRepository;
import com.vn.smart_space.repository.SosAlertRepository;
import com.vn.smart_space.repository.SosLocationPointRepository;
import com.vn.smart_space.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class SosServiceImplTest {

    @Mock
    SosAlertRepository sosRepository;
    @Mock
    SosLocationPointRepository pointRepository;
    @Mock
    UserRepository userRepository;
    @Mock
    EmergencyContactRepository contactRepository;
    @Mock
    SosNotifier notifier;
    @Mock
    SosRateLimitService rateLimitService;

    @InjectMocks
    SosServiceImpl service;

    @Test
    void startNotifiesActiveAdminsAppContactsByPushAndPhoneContactsBySms() {
        User owner = user("owner", ERole.client, EUserStatus.active);
        User linked = user("linked", ERole.client, EUserStatus.active);
        User admin = user("admin", ERole.admin, EUserStatus.active);
        User lockedAdmin = user("admin-locked", ERole.admin, EUserStatus.blocked);
        EmergencyContact appContact = contact(owner, linked, EEmergencyContactConsent.APP, "84900000001");
        EmergencyContact phoneContact = contact(owner, null, EEmergencyContactConsent.SELF_DECLARED, "84900000002");

        when(userRepository.findByIdForUpdate("owner")).thenReturn(Optional.of(owner));
        when(sosRepository.findByUserAndStatuses(eq("owner"), anyCollection())).thenReturn(List.of());
        when(rateLimitService.getRemainingCooldownSeconds("owner")).thenReturn(0L);
        when(rateLimitService.tryConsumeSmsQuota("owner")).thenReturn(true);
        when(contactRepository.findByOwnerAndStatus("owner", EEmergencyContactStatus.ACCEPTED))
                .thenReturn(List.of(appContact, phoneContact));
        when(userRepository.findByRole(ERole.admin)).thenReturn(List.of(admin, lockedAdmin));
        when(sosRepository.saveAndFlush(any(SosAlert.class))).thenAnswer(inv -> {
            SosAlert saved = inv.getArgument(0);
            saved.setId("sos-1");
            return saved;
        });

        SosAlertResponse response = service.start("owner", startRequest());

        assertEquals("sos-1", response.getId());
        assertEquals("ACTIVE", response.getStatus());
        assertEquals(2, response.getNotifiedContacts());
        verify(pointRepository).save(any(SosLocationPoint.class));

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<User>> admins = ArgumentCaptor.forClass(List.class);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<User>> appContacts = ArgumentCaptor.forClass(List.class);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<String>> phones = ArgumentCaptor.forClass(List.class);
        verify(notifier).notifyStarted(any(), eq(owner), admins.capture(), appContacts.capture(), phones.capture());
        assertEquals(List.of(admin), admins.getValue());
        assertEquals(List.of(linked), appContacts.getValue());
        assertEquals(List.of("84900000002"), phones.getValue());
    }

    @Test
    void startWhileOpenReturnsSameSosAndNotifiesLocationWithoutAlertingAgain() {
        User owner = user("owner", ERole.client, EUserStatus.active);
        User admin = user("admin", ERole.admin, EUserStatus.active);
        SosAlert open = sos("sos-1", owner, ESosStatus.ACTIVE, LocalDateTime.now().minusSeconds(30));

        when(userRepository.findByIdForUpdate("owner")).thenReturn(Optional.of(owner));
        when(sosRepository.findByUserAndStatuses(eq("owner"), anyCollection())).thenReturn(List.of(open));
        when(userRepository.findByRole(ERole.admin)).thenReturn(List.of(admin));
        when(contactRepository.findByOwnerAndStatus("owner", EEmergencyContactStatus.ACCEPTED))
                .thenReturn(List.of());

        SosAlertResponse response = service.start("owner", startRequest());

        assertEquals("sos-1", response.getId());
        assertEquals(10.5, open.getLatitude());
        verify(notifier, never()).notifyStarted(any(), any(), anyList(), anyList(), anyList());
        verify(notifier).notifyLocation(any(), anyCollection());
    }

    @Test
    void startByLockedAccountIsForbidden() {
        when(userRepository.findByIdForUpdate("owner"))
                .thenReturn(Optional.of(user("owner", ERole.client, EUserStatus.blocked)));

        assertThrows(AccessDeniedException.class, () -> service.start("owner", startRequest()));
    }

    @Test
    void locationUpdateSentTooSoonIsIgnored() {
        User owner = user("owner", ERole.client, EUserStatus.active);
        SosAlert open = sos("sos-1", owner, ESosStatus.ACTIVE, LocalDateTime.now().minusSeconds(2));
        when(sosRepository.lockById("sos-1")).thenReturn(Optional.of(open));
        when(sosRepository.findDetail("sos-1")).thenReturn(Optional.of(open));

        service.updateLocation("owner", "sos-1", new SosLocationRequest(11.0, 107.0, 5.0));

        assertEquals(1.0, open.getLatitude());
        verify(pointRepository, never()).save(any());
        verify(notifier, never()).notifyLocation(any(), anyCollection());
    }

    @Test
    void markSafeBySomeoneElseIsForbidden() {
        SosAlert open = sos("sos-1", user("owner", ERole.client, EUserStatus.active), ESosStatus.ACTIVE,
                LocalDateTime.now());
        when(sosRepository.lockById("sos-1")).thenReturn(Optional.of(open));
        when(sosRepository.findDetail("sos-1")).thenReturn(Optional.of(open));

        assertThrows(AccessDeniedException.class, () -> service.markSafe("stranger", "sos-1"));
        assertTrue(open.getStatus().isOpen());
    }

    @Test
    void acknowledgeTwiceIsRejected() {
        SosAlert taken = sos("sos-1", user("owner", ERole.client, EUserStatus.active), ESosStatus.ACKNOWLEDGED,
                LocalDateTime.now());
        when(sosRepository.lockById("sos-1")).thenReturn(Optional.of(taken));
        when(sosRepository.findDetail("sos-1")).thenReturn(Optional.of(taken));

        assertThrows(BadRequestException.class, () -> service.acknowledge("admin", "sos-1"));
    }

    @Test
    void onlyOwnerOrAcceptedContactCanViewSos() {
        User owner = user("owner", ERole.client, EUserStatus.active);
        SosAlert open = sos("sos-1", owner, ESosStatus.ACTIVE, LocalDateTime.now());
        when(sosRepository.findDetail("sos-1")).thenReturn(Optional.of(open));
        when(contactRepository.existsByOwnerIdAndLinkedUserIdAndStatus("owner", "guardian",
                EEmergencyContactStatus.ACCEPTED)).thenReturn(true);
        when(contactRepository.existsByOwnerIdAndLinkedUserIdAndStatus("owner", "stranger",
                EEmergencyContactStatus.ACCEPTED)).thenReturn(false);

        assertEquals("sos-1", service.getForViewer("owner", "sos-1").getId());
        assertEquals("sos-1", service.getForViewer("guardian", "sos-1").getId());
        assertThrows(AccessDeniedException.class, () -> service.getForViewer("stranger", "sos-1"));
    }

    @Test
    void resolveByAdminClosesSosAndQueriesRecipientsOnce() {
        User owner = user("owner", ERole.client, EUserStatus.active);
        User admin = user("admin", ERole.admin, EUserStatus.active);
        SosAlert open = sos("sos-1", owner, ESosStatus.ACKNOWLEDGED, LocalDateTime.now());

        when(sosRepository.lockById("sos-1")).thenReturn(Optional.of(open));
        when(sosRepository.findDetail("sos-1")).thenReturn(Optional.of(open));
        when(userRepository.findById("admin")).thenReturn(Optional.of(admin));
        when(userRepository.findByRole(ERole.admin)).thenReturn(List.of(admin));
        when(contactRepository.findByOwnerAndStatus("owner", EEmergencyContactStatus.ACCEPTED))
                .thenReturn(List.of());

        SosAlertResponse response = service.resolve("admin", "sos-1",
                ResolveSosRequest.builder().falseAlarm(true).note("  Accidental trigger  ").build());

        assertEquals("RESOLVED", response.getStatus());
        assertEquals(ESosResolution.FALSE_ALARM.name(), response.getResolution());
        assertEquals("Accidental trigger", response.getResolutionNote());
        verify(userRepository, times(1)).findByRole(ERole.admin);
        verify(contactRepository, times(1)).findByOwnerAndStatus("owner", EEmergencyContactStatus.ACCEPTED);
        verify(rateLimitService).recordCooldown("owner", ESosResolution.FALSE_ALARM);
        verify(notifier).notifyResolved(any(), eq(owner), eq("false_alarm"), eq(true), anyList(), anyList(),
                anyList(), anyCollection());
    }

    @Test
    void startBlockedDuringCooldown() {
        User owner = user("owner", ERole.client, EUserStatus.active);
        when(userRepository.findByIdForUpdate("owner")).thenReturn(Optional.of(owner));
        when(sosRepository.findByUserAndStatuses(eq("owner"), anyCollection())).thenReturn(List.of());
        when(rateLimitService.getRemainingCooldownSeconds("owner")).thenReturn(125L);

        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> service.start("owner", startRequest()));
        assertEquals("sos.cooldown.minutes", ex.getMessage());
        assertEquals(3L, ex.getArgs()[0]);
        verify(sosRepository, never()).saveAndFlush(any());
    }

    @Test
    void startSuppressesSmsWhenDailyQuotaExceededButStillNotifiesAppAndAdmins() {
        User owner = user("owner", ERole.client, EUserStatus.active);
        User linked = user("linked", ERole.client, EUserStatus.active);
        User admin = user("admin", ERole.admin, EUserStatus.active);
        EmergencyContact appContact = contact(owner, linked, EEmergencyContactConsent.APP, "84900000001");
        EmergencyContact phoneContact = contact(owner, null, EEmergencyContactConsent.SELF_DECLARED, "84900000002");

        when(userRepository.findByIdForUpdate("owner")).thenReturn(Optional.of(owner));
        when(sosRepository.findByUserAndStatuses(eq("owner"), anyCollection())).thenReturn(List.of());
        when(rateLimitService.getRemainingCooldownSeconds("owner")).thenReturn(0L);
        when(rateLimitService.tryConsumeSmsQuota("owner")).thenReturn(false);
        when(contactRepository.findByOwnerAndStatus("owner", EEmergencyContactStatus.ACCEPTED))
                .thenReturn(List.of(appContact, phoneContact));
        when(userRepository.findByRole(ERole.admin)).thenReturn(List.of(admin));
        when(sosRepository.saveAndFlush(any(SosAlert.class))).thenAnswer(inv -> {
            SosAlert saved = inv.getArgument(0);
            saved.setId("sos-2");
            return saved;
        });

        service.start("owner", startRequest());

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<String>> phones = ArgumentCaptor.forClass(List.class);
        verify(notifier).notifyStarted(any(), eq(owner), eq(List.of(admin)), eq(List.of(linked)), phones.capture());
        assertTrue(phones.getValue().isEmpty());
    }

    @Test
    void resolveAlreadyClosedSosIsRejected() {
        SosAlert closed = sos("sos-1", user("owner", ERole.client, EUserStatus.active), ESosStatus.RESOLVED,
                LocalDateTime.now());
        when(sosRepository.lockById("sos-1")).thenReturn(Optional.of(closed));
        when(sosRepository.findDetail("sos-1")).thenReturn(Optional.of(closed));

        assertThrows(BadRequestException.class,
                () -> service.resolve("admin", "sos-1", ResolveSosRequest.builder().falseAlarm(false).build()));
    }

    // Helpers

    private static StartSosRequest startRequest() {
        return StartSosRequest.builder().latitude(10.5).longitude(106.7).accuracy(8.0).build();
    }

    private static User user(String id, ERole role, EUserStatus status) {
        User user = User.builder().fullName(id).role(role).status(status).build();
        user.setId(id);
        return user;
    }

    private static EmergencyContact contact(User owner, User linked, EEmergencyContactConsent channel, String phone) {
        return EmergencyContact.builder()
                .owner(owner)
                .linkedUser(linked)
                .consentChannel(channel)
                .status(EEmergencyContactStatus.ACCEPTED)
                .phone(phone)
                .name("contact")
                .priority(0)
                .build();
    }

    private static SosAlert sos(String id, User owner, ESosStatus status, LocalDateTime lastLocationAt) {
        SosAlert sos = SosAlert.builder()
                .user(owner)
                .status(status)
                .latitude(1.0)
                .longitude(2.0)
                .lastLocationAt(lastLocationAt)
                .build();
        sos.setId(id);
        return sos;
    }
}
