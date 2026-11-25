package com.vn.smart_space.service.emergency;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InOrder;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import com.vn.smart_space.consts.EEmergencyContactConsent;
import com.vn.smart_space.consts.EEmergencyContactStatus;
import com.vn.smart_space.consts.EEmergencyRelationship;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.request.emergency.EmergencyContactRequest;
import com.vn.smart_space.dto.request.emergency.ReorderEmergencyContactsRequest;
import com.vn.smart_space.dto.response.emergency.EmergencyContactResponse;
import com.vn.smart_space.dto.response.emergency.GuardianshipResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.model.EmergencyContact;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.EmergencyContactRepository;
import com.vn.smart_space.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class EmergencyContactServiceImplTest {

    private static final String OWNER_ID = "owner-1";
    private static final String LINKED_ID = "linked-1";
    private static final String CONTACT_ID = "contact-1";

    @Mock
    EmergencyContactRepository contactRepository;
    @Mock
    UserRepository userRepository;
    @Mock
    EmergencyContactNotifier notifier;

    @InjectMocks
    EmergencyContactServiceImpl service;

    private static User user(String id, String email, ERole role, EUserStatus status) {
        User u = User.builder()
                .fullName("User " + id)
                .email(email)
                .phone("0912345678")
                .role(role)
                .status(status)
                .build();
        u.setId(id);
        return u;
    }

    private static EmergencyContact contact(String id, User owner, String phone, int priority,
            User linked, EEmergencyContactStatus status, EEmergencyContactConsent consent) {
        EmergencyContact c = EmergencyContact.builder()
                .owner(owner)
                .name("Contact " + id)
                .phone(phone)
                .relationship(EEmergencyRelationship.PARENT)
                .linkedUser(linked)
                .status(status)
                .consentChannel(consent)
                .priority(priority)
                .consentAt(status == EEmergencyContactStatus.ACCEPTED ? LocalDateTime.now() : null)
                .build();
        c.setId(id);
        return c;
    }

    @Nested
    class CreateTests {

        @Test
        void createsAppContactAndNotifiesAfterFlushWithGeneratedId() {
            User owner = user(OWNER_ID, "owner@example.com", ERole.client, EUserStatus.active);
            User linked = user(LINKED_ID, "friend@example.com", ERole.client, EUserStatus.active);
            when(userRepository.findByIdForUpdate(OWNER_ID)).thenReturn(Optional.of(owner));
            when(contactRepository.findAllByOwner(OWNER_ID)).thenReturn(List.of());
            when(userRepository.findByEmailAndRole("friend@example.com", ERole.client))
                    .thenReturn(Optional.of(linked));
            when(contactRepository.saveAndFlush(any(EmergencyContact.class))).thenAnswer(inv -> {
                EmergencyContact saved = inv.getArgument(0);
                saved.setId("generated-uuid");
                return saved;
            });

            EmergencyContactRequest req = EmergencyContactRequest.builder()
                    .name("  Minh Khoa ")
                    .phone("0987654321")
                    .relationship(EEmergencyRelationship.FRIEND)
                    .accountEmail(" friend@example.com ")
                    .build();

            EmergencyContactResponse res = service.create(OWNER_ID, req);

            assertEquals("generated-uuid", res.getId());
            assertEquals("Minh Khoa", res.getName());
            assertEquals("0987654321", res.getPhone());
            assertEquals("PENDING", res.getStatus());
            assertEquals("APP", res.getConsentChannel());
            assertEquals(0, res.getPriority());

            InOrder order = inOrder(contactRepository, notifier);
            order.verify(contactRepository).saveAndFlush(any(EmergencyContact.class));
            order.verify(notifier).notify(
                    eq(linked),
                    eq("notification.emergency_contact.invited.title"),
                    eq("notification.emergency_contact.invited.message"),
                    any(Object[].class),
                    eq("generated-uuid"),
                    eq(EmergencyContactNotifier.VIEW_GUARDIAN));
        }

        @Test
        void createsSelfDeclaredSmsContactWithoutNotification() {
            User owner = user(OWNER_ID, "owner@example.com", ERole.client, EUserStatus.active);
            when(userRepository.findByIdForUpdate(OWNER_ID)).thenReturn(Optional.of(owner));
            when(contactRepository.findAllByOwner(OWNER_ID)).thenReturn(List.of());
            when(contactRepository.saveAndFlush(any(EmergencyContact.class))).thenAnswer(inv -> {
                EmergencyContact saved = inv.getArgument(0);
                saved.setId("sms-uuid");
                return saved;
            });

            EmergencyContactRequest req = EmergencyContactRequest.builder()
                    .name("Mẹ")
                    .phone("+84 912-345-678")
                    .relationship(EEmergencyRelationship.PARENT)
                    .consentConfirmed(true)
                    .build();

            EmergencyContactResponse res = service.create(OWNER_ID, req);

            assertEquals("ACCEPTED", res.getStatus());
            assertEquals("SELF_DECLARED", res.getConsentChannel());
            assertEquals("0912345678", res.getPhone());
            assertNotNull(res.getConsentAt());
            verifyNoInteractions(notifier);
        }

        @Test
        void rejectsWhenLimitReached() {
            User owner = user(OWNER_ID, "owner@example.com", ERole.client, EUserStatus.active);
            when(userRepository.findByIdForUpdate(OWNER_ID)).thenReturn(Optional.of(owner));
            List<EmergencyContact> five = List.of(
                    contact("1", owner, "84900000001", 0, null, EEmergencyContactStatus.ACCEPTED, EEmergencyContactConsent.SELF_DECLARED),
                    contact("2", owner, "84900000002", 1, null, EEmergencyContactStatus.ACCEPTED, EEmergencyContactConsent.SELF_DECLARED),
                    contact("3", owner, "84900000003", 2, null, EEmergencyContactStatus.ACCEPTED, EEmergencyContactConsent.SELF_DECLARED),
                    contact("4", owner, "84900000004", 3, null, EEmergencyContactStatus.ACCEPTED, EEmergencyContactConsent.SELF_DECLARED),
                    contact("5", owner, "84900000005", 4, null, EEmergencyContactStatus.ACCEPTED, EEmergencyContactConsent.SELF_DECLARED));
            when(contactRepository.findAllByOwner(OWNER_ID)).thenReturn(five);

            EmergencyContactRequest req = EmergencyContactRequest.builder()
                    .name("Extra")
                    .phone("0900000006")
                    .relationship(EEmergencyRelationship.OTHER)
                    .consentConfirmed(true)
                    .build();

            BadRequestException ex = assertThrows(BadRequestException.class, () -> service.create(OWNER_ID, req));
            assertEquals("emergency_contact.limit_reached", ex.getMessage());
        }

        @Test
        void rejectsSelfDeclaredWithoutConsent() {
            User owner = user(OWNER_ID, "owner@example.com", ERole.client, EUserStatus.active);
            when(userRepository.findByIdForUpdate(OWNER_ID)).thenReturn(Optional.of(owner));
            when(contactRepository.findAllByOwner(OWNER_ID)).thenReturn(List.of());

            EmergencyContactRequest req = EmergencyContactRequest.builder()
                    .name("Mẹ")
                    .phone("0912345678")
                    .relationship(EEmergencyRelationship.PARENT)
                    .consentConfirmed(false)
                    .build();

            BadRequestException ex = assertThrows(BadRequestException.class, () -> service.create(OWNER_ID, req));
            assertEquals("emergency_contact.consent.required", ex.getMessage());
        }

        @Test
        void rejectsSelfLinkAndDuplicatePhone() {
            User owner = user(OWNER_ID, "owner@example.com", ERole.client, EUserStatus.active);
            EmergencyContact existing = contact("c1", owner, "84912345678", 0, null,
                    EEmergencyContactStatus.ACCEPTED, EEmergencyContactConsent.SELF_DECLARED);
            when(userRepository.findByIdForUpdate(OWNER_ID)).thenReturn(Optional.of(owner));
            when(contactRepository.findAllByOwner(OWNER_ID)).thenReturn(List.of(existing));
            when(userRepository.findByEmailAndRole("owner@example.com", ERole.client))
                    .thenReturn(Optional.of(owner));

            EmergencyContactRequest selfReq = EmergencyContactRequest.builder()
                    .name("Me")
                    .phone("0988888888")
                    .relationship(EEmergencyRelationship.OTHER)
                    .accountEmail("owner@example.com")
                    .build();
            BadRequestException selfEx = assertThrows(BadRequestException.class,
                    () -> service.create(OWNER_ID, selfReq));
            assertEquals("emergency_contact.self_not_allowed", selfEx.getMessage());

            EmergencyContactRequest dupPhoneReq = EmergencyContactRequest.builder()
                    .name("Dup")
                    .phone("0912345678")
                    .relationship(EEmergencyRelationship.OTHER)
                    .consentConfirmed(true)
                    .build();
            BadRequestException dupEx = assertThrows(BadRequestException.class,
                    () -> service.create(OWNER_ID, dupPhoneReq));
            assertEquals("emergency_contact.phone.duplicate", dupEx.getMessage());
        }
    }

    @Nested
    class UpdateAndReorderTests {

        @Test
        void updateSwitchingToAppAccountResetsToPendingAndNotifies() {
            User owner = user(OWNER_ID, "owner@example.com", ERole.client, EUserStatus.active);
            User linked = user(LINKED_ID, "linked@example.com", ERole.client, EUserStatus.active);
            EmergencyContact existing = contact(CONTACT_ID, owner, "84912345678", 0, null,
                    EEmergencyContactStatus.ACCEPTED, EEmergencyContactConsent.SELF_DECLARED);

            when(userRepository.findByIdForUpdate(OWNER_ID)).thenReturn(Optional.of(owner));
            when(contactRepository.findByIdAndOwner(CONTACT_ID, OWNER_ID)).thenReturn(Optional.of(existing));
            when(userRepository.findByEmailAndRole("linked@example.com", ERole.client))
                    .thenReturn(Optional.of(linked));
            when(contactRepository.findAllByOwner(OWNER_ID)).thenReturn(List.of(existing));

            EmergencyContactRequest req = EmergencyContactRequest.builder()
                    .name("Updated Name")
                    .phone("0912345678")
                    .relationship(EEmergencyRelationship.SIBLING)
                    .accountEmail("linked@example.com")
                    .build();

            EmergencyContactResponse res = service.update(OWNER_ID, CONTACT_ID, req);

            assertEquals("PENDING", res.getStatus());
            assertEquals("APP", res.getConsentChannel());
            assertNull(res.getConsentAt());
            verify(notifier).notify(eq(linked), eq("notification.emergency_contact.invited.title"),
                    eq("notification.emergency_contact.invited.message"), any(Object[].class),
                    eq(CONTACT_ID), eq(EmergencyContactNotifier.VIEW_GUARDIAN));
        }

        @Test
        void reorderUpdatesPrioritiesAndRejectsInvalidIds() {
            User owner = user(OWNER_ID, "owner@example.com", ERole.client, EUserStatus.active);
            EmergencyContact c1 = contact("c1", owner, "84911111111", 0, null,
                    EEmergencyContactStatus.ACCEPTED, EEmergencyContactConsent.SELF_DECLARED);
            EmergencyContact c2 = contact("c2", owner, "84922222222", 1, null,
                    EEmergencyContactStatus.ACCEPTED, EEmergencyContactConsent.SELF_DECLARED);

            when(userRepository.findByIdForUpdate(OWNER_ID)).thenReturn(Optional.of(owner));
            when(contactRepository.findAllByOwner(OWNER_ID)).thenReturn(List.of(c1, c2));

            List<EmergencyContactResponse> reordered = service.reorder(OWNER_ID,
                    new ReorderEmergencyContactsRequest(List.of("c2", "c1")));
            assertEquals(List.of("c2", "c1"), reordered.stream().map(EmergencyContactResponse::getId).toList());
            assertEquals(0, c2.getPriority());
            assertEquals(1, c1.getPriority());

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.reorder(OWNER_ID, new ReorderEmergencyContactsRequest(List.of("c1", "c1"))));
            assertEquals("emergency_contact.order.invalid", ex.getMessage());
        }
    }

    @Nested
    class GuardianshipTests {

        @Test
        void acceptRejectAndRevokeValidateStatusAndNotifyOwner() {
            User owner = user(OWNER_ID, "owner@example.com", ERole.client, EUserStatus.active);
            User guardian = user(LINKED_ID, "guardian@example.com", ERole.client, EUserStatus.active);
            EmergencyContact pending = contact(CONTACT_ID, owner, "84987654321", 0, guardian,
                    EEmergencyContactStatus.PENDING, EEmergencyContactConsent.APP);
            when(contactRepository.findByIdAndLinkedUser(CONTACT_ID, LINKED_ID))
                    .thenReturn(Optional.of(pending));

            GuardianshipResponse accepted = service.acceptInvitation(LINKED_ID, CONTACT_ID);
            assertEquals("ACCEPTED", accepted.getStatus());
            assertNotNull(accepted.getConsentAt());
            verify(notifier).notify(eq(owner), eq("notification.emergency_contact.accepted.title"),
                    eq("notification.emergency_contact.accepted.message"), any(Object[].class),
                    eq(CONTACT_ID), eq(EmergencyContactNotifier.VIEW_CONTACTS));

            // Đã accepted thì không thể reject nữa
            BadRequestException rejectEx = assertThrows(BadRequestException.class,
                    () -> service.rejectInvitation(LINKED_ID, CONTACT_ID));
            assertEquals("emergency_contact.invitation.not_pending", rejectEx.getMessage());

            // Revoke thành công khi đang ACCEPTED
            service.revokeGuardianship(LINKED_ID, CONTACT_ID);
            assertEquals(EEmergencyContactStatus.REVOKED, pending.getStatus());
            assertNull(pending.getConsentAt());
            verify(notifier).notify(eq(owner), eq("notification.emergency_contact.revoked.title"),
                    eq("notification.emergency_contact.revoked.message"), any(Object[].class),
                    eq(CONTACT_ID), eq(EmergencyContactNotifier.VIEW_CONTACTS));
        }

        @Test
        void rejectsActionFromLockedGuardian() {
            User owner = user(OWNER_ID, "owner@example.com", ERole.client, EUserStatus.active);
            User lockedGuardian = user(LINKED_ID, "guardian@example.com", ERole.client, EUserStatus.blocked);
            EmergencyContact pending = contact(CONTACT_ID, owner, "84987654321", 0, lockedGuardian,
                    EEmergencyContactStatus.PENDING, EEmergencyContactConsent.APP);
            when(contactRepository.findByIdAndLinkedUser(CONTACT_ID, LINKED_ID))
                    .thenReturn(Optional.of(pending));

            assertThrows(AccessDeniedException.class, () -> service.acceptInvitation(LINKED_ID, CONTACT_ID));
            verifyNoInteractions(notifier);
        }
    }
}
