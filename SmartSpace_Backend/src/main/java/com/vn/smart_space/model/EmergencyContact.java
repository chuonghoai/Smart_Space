package com.vn.smart_space.model;

import java.time.LocalDateTime;

import com.vn.smart_space.consts.EEmergencyContactConsent;
import com.vn.smart_space.consts.EEmergencyContactStatus;
import com.vn.smart_space.consts.EEmergencyRelationship;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.FieldDefaults;

/**
 * Người quen trong danh sách khẩn cấp của một cư dân (owner).
 */
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@Table(name = "emergency_contacts", indexes = {
        @Index(name = "idx_emergency_contact_owner", columnList = "owner_id, priority"),
        @Index(name = "idx_emergency_contact_linked_status", columnList = "linked_user_id, status")
})
public class EmergencyContact extends AbstractEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    User owner;

    @Column(name = "name", nullable = false, length = 100)
    String name;

    /** Đã chuẩn hoá dạng 84xxxxxxxxx. */
    @Column(name = "phone", nullable = false, length = 15)
    String phone;

    @Enumerated(EnumType.STRING)
    @Column(name = "relationship", nullable = false, columnDefinition = "VARCHAR(20)")
    EEmergencyRelationship relationship;

    /** Tài khoản cư dân được liên kết; null khi liên hệ không dùng app. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "linked_user_id")
    User linkedUser;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    @Column(name = "status", nullable = false, columnDefinition = "VARCHAR(20)")
    EEmergencyContactStatus status = EEmergencyContactStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(name = "consent_channel", nullable = false, columnDefinition = "VARCHAR(20)")
    EEmergencyContactConsent consentChannel;

    @Column(name = "priority", nullable = false)
    Integer priority;

    @Column(name = "consent_at")
    LocalDateTime consentAt;
}
