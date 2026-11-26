package com.vn.smart_space.service.sos;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.EEmergencyContactConsent;
import com.vn.smart_space.consts.EEmergencyContactStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.ESosResolution;
import com.vn.smart_space.consts.ESosStatus;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.sos.ResolveSosRequest;
import com.vn.smart_space.dto.request.sos.SosLocationRequest;
import com.vn.smart_space.dto.request.sos.StartSosRequest;
import com.vn.smart_space.dto.response.sos.SosAlertResponse;
import com.vn.smart_space.dto.response.sos.SosLocationPointResponse;
import com.vn.smart_space.dto.response.sos.SosUserResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.model.EmergencyContact;
import com.vn.smart_space.model.SosAlert;
import com.vn.smart_space.model.SosLocationPoint;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.EmergencyContactRepository;
import com.vn.smart_space.repository.SosAlertRepository;
import com.vn.smart_space.repository.SosLocationPointRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.utils.PhoneNumberUtils;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

/**
 * SOS của cư dân: báo toàn bộ admin và các liên hệ khẩn cấp đã đồng ý,
 * nhận vị trí định kỳ cho tới khi người gửi an toàn hoặc admin kết thúc.
 */
@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SosServiceImpl implements ISosService {

    /** Bỏ qua cập nhật vị trí dày hơn mức này (client gửi mỗi ~15 giây). */
    static final Duration MIN_LOCATION_INTERVAL = Duration.ofSeconds(5);
    static final int MAX_PAGE_SIZE = 50;
    static final List<ESosStatus> OPEN = List.of(ESosStatus.ACTIVE, ESosStatus.ACKNOWLEDGED);

    SosAlertRepository sosRepository;
    SosLocationPointRepository pointRepository;
    UserRepository userRepository;
    EmergencyContactRepository contactRepository;
    SosNotifier notifier;

    // Cư dân

    @Override
    @Transactional
    public SosAlertResponse start(String userId, StartSosRequest request) {
        // Khoá user để hai lần bấm gần nhau không tạo hai SOS
        User user = userRepository.findByIdForUpdate(userId)
                .orElseThrow(() -> new ResourceNotFoundException("user.not_found"));
        if (user.getRole() != ERole.client || user.getStatus() != EUserStatus.active) {
            throw new AccessDeniedException("sos.forbidden");
        }

        SosAlert existing = findOpenOf(userId);
        if (existing != null) {
            boolean updated = applyLocation(existing, request.getLatitude(), request.getLongitude(),
                    request.getAccuracy());
            SosAlertResponse response = toResponse(existing, false);
            if (updated) {
                notifier.notifyLocation(response, watcherIds(existing));
            }
            return response;
        }

        List<EmergencyContact> contacts = contactRepository.findByOwnerAndStatus(userId,
                EEmergencyContactStatus.ACCEPTED);
        LocalDateTime now = LocalDateTime.now();
        SosAlert sos = SosAlert.builder()
                .user(user)
                .status(ESosStatus.ACTIVE)
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .accuracy(request.getAccuracy())
                .lastLocationAt(now)
                .message(trimToNull(request.getMessage()))
                .notifiedContacts(contacts.size())
                .build();
        sosRepository.saveAndFlush(sos);
        savePoint(sos, now);

        SosAlertResponse response = toResponse(sos, false);
        notifier.notifyStarted(response, user, admins(), appContacts(contacts), smsPhones(contacts));
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public SosAlertResponse getActive(String userId) {
        SosAlert sos = findOpenOf(userId);
        return sos != null ? toResponse(sos, false) : null;
    }

    @Override
    @Transactional
    public SosAlertResponse updateLocation(String userId, String sosId, SosLocationRequest request) {
        SosAlert sos = findOwnedOpen(userId, sosId);
        if (applyLocation(sos, request.getLatitude(), request.getLongitude(), request.getAccuracy())) {
            SosAlertResponse response = toResponse(sos, false);
            notifier.notifyLocation(response, watcherIds(sos));
            return response;
        }
        return toResponse(sos, false);
    }

    @Override
    @Transactional
    public SosAlertResponse markSafe(String userId, String sosId) {
        SosAlert sos = findOwnedOpen(userId, sosId);
        close(sos, sos.getUser(), ESosResolution.SAFE_BY_USER, null);
        return notifyClosed(sos, "safe", false);
    }

    @Override
    @Transactional(readOnly = true)
    public SosAlertResponse getForViewer(String viewerId, String sosId) {
        SosAlert sos = sosRepository.findDetail(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("sos.not_found"));
        String ownerId = sos.getUser().getId();
        boolean allowed = ownerId.equals(viewerId) || contactRepository
                .existsByOwnerIdAndLinkedUserIdAndStatus(ownerId, viewerId, EEmergencyContactStatus.ACCEPTED);
        if (!allowed) {
            throw new AccessDeniedException("sos.forbidden");
        }
        return toResponse(sos, false);
    }

    // Admin

    @Override
    @Transactional(readOnly = true)
    public PageResponse<SosAlertResponse> list(String status, int page, int size) {
        List<ESosStatus> statuses = switch (status == null ? "" : status.trim().toLowerCase()) {
            case "open" -> OPEN;
            case "resolved" -> List.of(ESosStatus.RESOLVED);
            case "all", "" -> List.of(ESosStatus.values());
            default -> throw new BadRequestException("sos.invalid_status");
        };
        int safePage = Math.max(1, page);
        int safeSize = Math.min(Math.max(1, size), MAX_PAGE_SIZE);
        Page<SosAlert> result = sosRepository.findByStatusIn(statuses,
                PageRequest.of(safePage - 1, safeSize, Sort.by(Sort.Direction.DESC, "createdAt")));
        return PageResponse.<SosAlertResponse>builder()
                .currentPage(safePage)
                .pageSize(safeSize)
                .totalPages(result.getTotalPages())
                .totalElements(result.getTotalElements())
                .content(result.getContent().stream().map(s -> toResponse(s, false)).toList())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public Map<String, Long> openCount() {
        return Map.of("count", sosRepository.countByStatusIn(OPEN));
    }

    @Override
    @Transactional(readOnly = true)
    public SosAlertResponse getDetail(String sosId) {
        SosAlert sos = sosRepository.findDetail(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("sos.not_found"));
        return toResponse(sos, true);
    }

    @Override
    @Transactional
    public SosAlertResponse acknowledge(String adminId, String sosId) {
        SosAlert sos = lockDetail(sosId);
        if (sos.getStatus() != ESosStatus.ACTIVE) {
            throw new BadRequestException("sos.not_active");
        }
        User admin = userRepository.findById(adminId)
                .orElseThrow(() -> new ResourceNotFoundException("user.not_found"));
        sos.setStatus(ESosStatus.ACKNOWLEDGED);
        sos.setAcknowledgedBy(admin);
        sos.setAcknowledgedAt(LocalDateTime.now());

        SosAlertResponse response = toResponse(sos, false);
        notifier.notifyAcknowledged(response, sos.getUser(), admin, watcherIds(sos));
        return response;
    }

    @Override
    @Transactional
    public SosAlertResponse resolve(String adminId, String sosId, ResolveSosRequest request) {
        SosAlert sos = lockDetail(sosId);
        if (!sos.getStatus().isOpen()) {
            throw new BadRequestException("sos.already_resolved");
        }
        User admin = userRepository.findById(adminId)
                .orElseThrow(() -> new ResourceNotFoundException("user.not_found"));
        ESosResolution resolution = request.isFalseAlarm() ? ESosResolution.FALSE_ALARM
                : ESosResolution.RESOLVED_BY_ADMIN;
        close(sos, admin, resolution, trimToNull(request.getNote()));
        return notifyClosed(sos, request.isFalseAlarm() ? "false_alarm" : "handled", true);
    }

    // Helpers

    private SosAlert findOpenOf(String userId) {
        List<SosAlert> open = sosRepository.findByUserAndStatuses(userId, OPEN);
        return open.isEmpty() ? null : open.get(0);
    }

    private SosAlert findOwnedOpen(String userId, String sosId) {
        SosAlert sos = lockDetail(sosId);
        if (!sos.getUser().getId().equals(userId)) {
            throw new AccessDeniedException("sos.forbidden");
        }
        if (!sos.getStatus().isOpen()) {
            throw new BadRequestException("sos.already_resolved");
        }
        return sos;
    }

    /**
     * Khoá dòng trước khi đọc để các thao tác đổi trạng thái đồng thời chỉ một bên
     * thắng.
     */
    private SosAlert lockDetail(String sosId) {
        sosRepository.lockById(sosId).orElseThrow(() -> new ResourceNotFoundException("sos.not_found"));
        return sosRepository.findDetail(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("sos.not_found"));
    }

    /** Trả về false nếu bị bỏ qua vì gửi quá dày. */
    private boolean applyLocation(SosAlert sos, Double latitude, Double longitude, Double accuracy) {
        LocalDateTime now = LocalDateTime.now();
        if (sos.getLastLocationAt() != null
                && Duration.between(sos.getLastLocationAt(), now).compareTo(MIN_LOCATION_INTERVAL) < 0) {
            return false;
        }
        sos.setLatitude(latitude);
        sos.setLongitude(longitude);
        sos.setAccuracy(accuracy);
        sos.setLastLocationAt(now);
        savePoint(sos, now);
        return true;
    }

    private void savePoint(SosAlert sos, LocalDateTime at) {
        pointRepository.save(SosLocationPoint.builder()
                .sosAlert(sos)
                .latitude(sos.getLatitude())
                .longitude(sos.getLongitude())
                .accuracy(sos.getAccuracy())
                .recordedAt(at)
                .build());
    }

    private static void close(SosAlert sos, User by, ESosResolution resolution, String note) {
        sos.setStatus(ESosStatus.RESOLVED);
        sos.setResolution(resolution);
        sos.setResolvedBy(by);
        sos.setResolvedAt(LocalDateTime.now());
        sos.setResolutionNote(note);
    }

    private SosAlertResponse notifyClosed(SosAlert sos, String outcome, boolean byAdmin) {
        List<EmergencyContact> contacts = contactRepository.findByOwnerAndStatus(sos.getUser().getId(),
                EEmergencyContactStatus.ACCEPTED);
        List<User> activeAdmins = admins();
        List<User> linkedContacts = appContacts(contacts);
        SosAlertResponse response = toResponse(sos, false);
        notifier.notifyResolved(response, sos.getUser(), outcome, byAdmin, activeAdmins, linkedContacts,
                smsPhones(contacts), watcherIds(sos.getUser().getId(), activeAdmins, linkedContacts));
        return response;
    }

    private List<User> admins() {
        return userRepository.findByRole(ERole.admin).stream()
                .filter(a -> a.getStatus() == EUserStatus.active)
                .toList();
    }

    private static List<User> appContacts(List<EmergencyContact> contacts) {
        return contacts.stream()
                .filter(c -> c.getConsentChannel() == EEmergencyContactConsent.APP && c.getLinkedUser() != null)
                .map(EmergencyContact::getLinkedUser)
                .toList();
    }

    /** Liên hệ không có tài khoản: chỉ liên lạc được bằng SMS. */
    private static List<String> smsPhones(List<EmergencyContact> contacts) {
        return contacts.stream()
                .filter(c -> c.getConsentChannel() == EEmergencyContactConsent.SELF_DECLARED)
                .map(EmergencyContact::getPhone)
                .toList();
    }

    /**
     * Người đang theo dõi realtime: người gửi, toàn bộ admin, liên hệ có tài khoản
     * đã đồng ý.
     */
    private Set<String> watcherIds(SosAlert sos) {
        List<User> linkedContacts = appContacts(
                contactRepository.findByOwnerAndStatus(sos.getUser().getId(), EEmergencyContactStatus.ACCEPTED));
        return watcherIds(sos.getUser().getId(), admins(), linkedContacts);
    }

    private static Set<String> watcherIds(String senderId, List<User> admins, List<User> appContacts) {
        Set<String> ids = new LinkedHashSet<>();
        ids.add(senderId);
        admins.forEach(a -> ids.add(a.getId()));
        appContacts.forEach(u -> ids.add(u.getId()));
        return ids;
    }

    private SosAlertResponse toResponse(SosAlert sos, boolean withTrack) {
        List<SosLocationPointResponse> track = withTrack
                ? pointRepository.findTop200BySosAlertIdOrderByRecordedAtDesc(sos.getId()).stream()
                        .map(p -> SosLocationPointResponse.builder()
                                .latitude(p.getLatitude())
                                .longitude(p.getLongitude())
                                .accuracy(p.getAccuracy())
                                .recordedAt(p.getRecordedAt())
                                .build())
                        .toList()
                : null;
        return SosAlertResponse.builder()
                .id(sos.getId())
                .status(sos.getStatus().name())
                .resolution(sos.getResolution() != null ? sos.getResolution().name() : null)
                .user(toUser(sos.getUser()))
                .latitude(sos.getLatitude())
                .longitude(sos.getLongitude())
                .accuracy(sos.getAccuracy())
                .lastLocationAt(sos.getLastLocationAt())
                .message(sos.getMessage())
                .notifiedContacts(sos.getNotifiedContacts())
                .acknowledgedBy(toUser(sos.getAcknowledgedBy()))
                .acknowledgedAt(sos.getAcknowledgedAt())
                .resolvedBy(toUser(sos.getResolvedBy()))
                .resolvedAt(sos.getResolvedAt())
                .resolutionNote(sos.getResolutionNote())
                .createdAt(sos.getCreatedAt())
                .track(track)
                .build();
    }

    private static SosUserResponse toUser(User user) {
        if (user == null) {
            return null;
        }
        String normalized = PhoneNumberUtils.normalizeVnMobile(user.getPhone());
        return SosUserResponse.builder()
                .id(user.getId())
                .fullName(SosNotifier.displayName(user))
                .avatarUrl(user.getAvatarUrl())
                .phone(normalized != null ? PhoneNumberUtils.toLocalFormat(normalized) : user.getPhone())
                .build();
    }

    private static String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
