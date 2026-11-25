package com.vn.smart_space.service.emergency;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.EEmergencyContactConsent;
import com.vn.smart_space.consts.EEmergencyContactStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.request.emergency.EmergencyContactRequest;
import com.vn.smart_space.dto.request.emergency.ReorderEmergencyContactsRequest;
import com.vn.smart_space.dto.response.emergency.EmergencyContactResponse;
import com.vn.smart_space.dto.response.emergency.EmergencyContactUserResponse;
import com.vn.smart_space.dto.response.emergency.GuardianshipResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.model.EmergencyContact;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.EmergencyContactRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.utils.PhoneNumberUtils;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

/**
 * Danh sách liên hệ khẩn cấp: liên hệ có tài khoản đồng ý qua lời mời trong app,
 * liên hệ không có tài khoản do owner tự xác nhận đồng ý (không tốn phí SMS khi thêm).
 */
@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class EmergencyContactServiceImpl implements IEmergencyContactService {

    static final int MAX_CONTACTS = 5;
    static final List<EEmergencyContactStatus> GUARDIAN_VISIBLE = List.of(EEmergencyContactStatus.PENDING,
            EEmergencyContactStatus.ACCEPTED);

    EmergencyContactRepository contactRepository;
    UserRepository userRepository;
    EmergencyContactNotifier notifier;

    // Phía owner

    @Override
    @Transactional(readOnly = true)
    public List<EmergencyContactResponse> listMine(String ownerId) {
        return contactRepository.findAllByOwner(ownerId).stream().map(this::toResponse).toList();
    }

    @Override
    @Transactional
    public EmergencyContactResponse create(String ownerId, EmergencyContactRequest request) {
        // Khoá owner để giới hạn số liên hệ và kiểm tra trùng không bị vượt khi chạy song song
        User owner = lockActiveClient(ownerId);

        List<EmergencyContact> existing = contactRepository.findAllByOwner(ownerId);
        if (existing.size() >= MAX_CONTACTS) {
            throw new BadRequestException("emergency_contact.limit_reached");
        }

        String phone = normalizePhone(request.getPhone());
        User linked = resolveLinkedUser(owner, request.getAccountEmail());
        requireConsentIfSelfDeclared(linked, request);
        ensureUnique(existing, null, phone, linked);

        EmergencyContact contact = EmergencyContact.builder()
                .owner(owner)
                .name(request.getName().trim())
                .phone(phone)
                .relationship(request.getRelationship())
                .priority(nextPriority(existing))
                .build();
        boolean shouldNotify = applyConsent(contact, linked);
        // Phải flush trước để có UUID cho payload thông báo lời mời
        contactRepository.saveAndFlush(contact);
        if (shouldNotify) {
            notifyInvitation(contact);
        }
        return toResponse(contact);
    }

    @Override
    @Transactional
    public EmergencyContactResponse update(String ownerId, String contactId, EmergencyContactRequest request) {
        User owner = lockActiveClient(ownerId);
        EmergencyContact contact = findOwned(ownerId, contactId);
        String phone = normalizePhone(request.getPhone());
        User linked = resolveLinkedUser(owner, request.getAccountEmail());
        requireConsentIfSelfDeclared(linked, request);
        ensureUnique(contactRepository.findAllByOwner(ownerId), contactId, phone, linked);

        String previousLinkedId = contact.getLinkedUser() != null ? contact.getLinkedUser().getId() : null;
        String newLinkedId = linked != null ? linked.getId() : null;
        // Đổi tài khoản liên kết, hoặc liên hệ SMS đổi số, thì phải xin đồng ý lại
        boolean identityChanged = !Objects.equals(previousLinkedId, newLinkedId)
                || (linked == null && !phone.equals(contact.getPhone()));

        contact.setName(request.getName().trim());
        contact.setRelationship(request.getRelationship());
        contact.setPhone(phone);
        if (identityChanged && applyConsent(contact, linked)) {
            notifyInvitation(contact);
        }
        return toResponse(contact);
    }

    @Override
    @Transactional
    public void delete(String ownerId, String contactId) {
        lockActiveClient(ownerId);
        contactRepository.delete(findOwned(ownerId, contactId));
    }

    @Override
    @Transactional
    public List<EmergencyContactResponse> reorder(String ownerId, ReorderEmergencyContactsRequest request) {
        lockActiveClient(ownerId);
        List<EmergencyContact> contacts = contactRepository.findAllByOwner(ownerId);
        List<String> ids = request.getContactIds();
        Set<String> requested = new HashSet<>(ids);
        Set<String> owned = new HashSet<>(contacts.stream().map(EmergencyContact::getId).toList());
        if (ids.size() != contacts.size() || requested.size() != ids.size() || !requested.equals(owned)) {
            throw new BadRequestException("emergency_contact.order.invalid");
        }

        Map<String, Integer> position = new HashMap<>();
        for (int i = 0; i < ids.size(); i++) {
            position.put(ids.get(i), i);
        }
        contacts.forEach(c -> c.setPriority(position.get(c.getId())));
        return contacts.stream()
                .sorted(Comparator.comparingInt(EmergencyContact::getPriority))
                .map(this::toResponse)
                .toList();
    }

    // Phía người được thêm

    @Override
    @Transactional(readOnly = true)
    public List<GuardianshipResponse> listGuardianships(String userId) {
        return contactRepository.findGuardianships(userId, GUARDIAN_VISIBLE).stream()
                .map(this::toGuardianship)
                .toList();
    }

    @Override
    @Transactional
    public GuardianshipResponse acceptInvitation(String userId, String contactId) {
        EmergencyContact contact = findGuarded(userId, contactId);
        requireActiveClient(contact.getLinkedUser());
        requirePending(contact);
        contact.setStatus(EEmergencyContactStatus.ACCEPTED);
        contact.setConsentAt(LocalDateTime.now());

        notifyOwner(contact, "accepted");
        return toGuardianship(contact);
    }

    @Override
    @Transactional
    public void rejectInvitation(String userId, String contactId) {
        EmergencyContact contact = findGuarded(userId, contactId);
        requireActiveClient(contact.getLinkedUser());
        requirePending(contact);
        contact.setStatus(EEmergencyContactStatus.REJECTED);

        notifyOwner(contact, "rejected");
    }

    @Override
    @Transactional
    public void revokeGuardianship(String userId, String contactId) {
        EmergencyContact contact = findGuarded(userId, contactId);
        requireActiveClient(contact.getLinkedUser());
        if (contact.getStatus() != EEmergencyContactStatus.ACCEPTED) {
            throw new BadRequestException("emergency_contact.not_accepted");
        }
        contact.setStatus(EEmergencyContactStatus.REVOKED);
        contact.setConsentAt(null);

        notifyOwner(contact, "revoked");
    }

    // Helpers

    /** Có tài khoản: chờ chấp nhận lời mời (trả true để gửi thông báo). Không có: hiệu lực ngay. */
    private boolean applyConsent(EmergencyContact contact, User linked) {
        contact.setLinkedUser(linked);
        if (linked != null) {
            contact.setConsentChannel(EEmergencyContactConsent.APP);
            contact.setStatus(EEmergencyContactStatus.PENDING);
            contact.setConsentAt(null);
            return true;
        }
        contact.setConsentChannel(EEmergencyContactConsent.SELF_DECLARED);
        contact.setStatus(EEmergencyContactStatus.ACCEPTED);
        contact.setConsentAt(LocalDateTime.now());
        return false;
    }

    private User lockActiveClient(String userId) {
        User user = userRepository.findByIdForUpdate(userId)
                .orElseThrow(() -> new ResourceNotFoundException("user.not_found"));
        requireActiveClient(user);
        return user;
    }

    private static void requireConsentIfSelfDeclared(User linked, EmergencyContactRequest request) {
        if (linked == null && !Boolean.TRUE.equals(request.getConsentConfirmed())) {
            throw new BadRequestException("emergency_contact.consent.required");
        }
    }

    private EmergencyContact findOwned(String ownerId, String contactId) {
        return contactRepository.findByIdAndOwner(contactId, ownerId)
                .orElseThrow(() -> new ResourceNotFoundException("emergency_contact.not_found"));
    }

    private EmergencyContact findGuarded(String userId, String contactId) {
        return contactRepository.findByIdAndLinkedUser(contactId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("emergency_contact.not_found"));
    }

    private static void requirePending(EmergencyContact contact) {
        if (contact.getStatus() != EEmergencyContactStatus.PENDING) {
            throw new BadRequestException("emergency_contact.invitation.not_pending");
        }
    }

    private static void requireActiveClient(User user) {
        if (user.getRole() != ERole.client || user.getStatus() != EUserStatus.active) {
            throw new AccessDeniedException("emergency_contact.forbidden");
        }
    }

    private static String normalizePhone(String raw) {
        String phone = PhoneNumberUtils.normalizeVnMobile(raw);
        if (phone == null) {
            throw new BadRequestException("emergency_contact.phone.invalid");
        }
        return phone;
    }

    /** Chỉ liên kết qua email chính xác (đã xác minh khi đăng ký) của một cư dân đang hoạt động. */
    private User resolveLinkedUser(User owner, String accountEmail) {
        if (accountEmail == null || accountEmail.isBlank()) {
            return null;
        }
        User linked = userRepository.findByEmailAndRole(accountEmail.trim(), ERole.client)
                .orElseThrow(() -> new BadRequestException("emergency_contact.account_not_found"));
        if (linked.getId().equals(owner.getId())) {
            throw new BadRequestException("emergency_contact.self_not_allowed");
        }
        if (linked.getStatus() != EUserStatus.active) {
            throw new BadRequestException("emergency_contact.account_inactive");
        }
        return linked;
    }

    private static void ensureUnique(List<EmergencyContact> existing, String excludeId, String phone, User linked) {
        for (EmergencyContact other : existing) {
            if (other.getId().equals(excludeId)) {
                continue;
            }
            if (other.getPhone().equals(phone)) {
                throw new BadRequestException("emergency_contact.phone.duplicate");
            }
            if (linked != null && other.getLinkedUser() != null
                    && other.getLinkedUser().getId().equals(linked.getId())) {
                throw new BadRequestException("emergency_contact.account.duplicate");
            }
        }
    }

    private static int nextPriority(List<EmergencyContact> existing) {
        return existing.stream().mapToInt(EmergencyContact::getPriority).max().orElse(-1) + 1;
    }

    private void notifyInvitation(EmergencyContact contact) {
        notifier.notify(contact.getLinkedUser(), "notification.emergency_contact.invited.title",
                "notification.emergency_contact.invited.message",
                new Object[] { EmergencyContactNotifier.displayName(contact.getOwner()) },
                contact.getId(), EmergencyContactNotifier.VIEW_GUARDIAN);
    }

    /** Báo owner kết quả phản hồi của người được mời: accepted | rejected | revoked. */
    private void notifyOwner(EmergencyContact contact, String outcome) {
        notifier.notify(contact.getOwner(), "notification.emergency_contact." + outcome + ".title",
                "notification.emergency_contact." + outcome + ".message",
                new Object[] { EmergencyContactNotifier.displayName(contact.getLinkedUser()) },
                contact.getId(), EmergencyContactNotifier.VIEW_CONTACTS);
    }

    private EmergencyContactResponse toResponse(EmergencyContact c) {
        return EmergencyContactResponse.builder()
                .id(c.getId())
                .name(c.getName())
                .phone(PhoneNumberUtils.toLocalFormat(c.getPhone()))
                .relationship(c.getRelationship().name())
                .status(c.getStatus().name())
                .consentChannel(c.getConsentChannel().name())
                .priority(c.getPriority())
                .linkedUser(toUser(c.getLinkedUser()))
                .accountEmail(c.getLinkedUser() != null ? c.getLinkedUser().getEmail() : null)
                .consentAt(c.getConsentAt())
                .createdAt(c.getCreatedAt())
                .build();
    }

    private GuardianshipResponse toGuardianship(EmergencyContact c) {
        return GuardianshipResponse.builder()
                .id(c.getId())
                .status(c.getStatus().name())
                .relationship(c.getRelationship().name())
                .owner(toUser(c.getOwner()))
                .ownerPhone(PhoneNumberUtils.toLocalFormat(c.getOwner().getPhone()))
                .consentAt(c.getConsentAt())
                .createdAt(c.getCreatedAt())
                .build();
    }

    private static EmergencyContactUserResponse toUser(User user) {
        if (user == null) {
            return null;
        }
        return EmergencyContactUserResponse.builder()
                .id(user.getId())
                .fullName(EmergencyContactNotifier.displayName(user))
                .avatarUrl(user.getAvatarUrl())
                .build();
    }
}
