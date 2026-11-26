package com.vn.smart_space.model;

import java.time.LocalDateTime;

import com.vn.smart_space.consts.ESosResolution;
import com.vn.smart_space.consts.ESosStatus;

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

/** Một lần cư dân gửi tín hiệu SOS, giữ vị trí mới nhất và trạng thái xử lý. */
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@Table(name = "sos_alerts", indexes = {
        @Index(name = "idx_sos_user_status", columnList = "user_id, status"),
        @Index(name = "idx_sos_status_created", columnList = "status, created_at")
})
public class SosAlert extends AbstractEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    User user;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    @Column(name = "status", nullable = false, columnDefinition = "VARCHAR(20)")
    ESosStatus status = ESosStatus.ACTIVE;

    @Enumerated(EnumType.STRING)
    @Column(name = "resolution", columnDefinition = "VARCHAR(30)")
    ESosResolution resolution;

    @Column(name = "latitude", nullable = false)
    Double latitude;

    @Column(name = "longitude", nullable = false)
    Double longitude;

    /** Bán kính sai số (mét) do thiết bị báo. */
    @Column(name = "accuracy")
    Double accuracy;

    @Column(name = "last_location_at", nullable = false)
    LocalDateTime lastLocationAt;

    @Column(name = "message", length = 500)
    String message;

    @Column(name = "notified_contacts", nullable = false)
    @Builder.Default
    Integer notifiedContacts = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "acknowledged_by")
    User acknowledgedBy;

    @Column(name = "acknowledged_at")
    LocalDateTime acknowledgedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resolved_by")
    User resolvedBy;

    @Column(name = "resolved_at")
    LocalDateTime resolvedAt;

    @Column(name = "resolution_note", length = 500)
    String resolutionNote;
}
