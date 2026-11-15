package com.vn.smart_space.model;

import java.time.LocalDateTime;

import com.vn.smart_space.consts.EAccountLockRequestStatus;

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
 * Đề xuất khóa tài khoản người dùng..
 */
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@Table(name = "account_lock_requests", indexes = {
        @Index(name = "idx_lock_req_status_created", columnList = "status, created_at"),
        @Index(name = "idx_lock_req_target_status", columnList = "target_id, status")
})
public class AccountLockRequest extends AbstractEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "target_id", nullable = false)
    User target;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "proposer_id", nullable = false)
    User proposer;

    @Column(name = "reason", columnDefinition = "TEXT", nullable = false)
    String reason;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, columnDefinition = "VARCHAR(20)")
    EAccountLockRequestStatus status;

    @Column(name = "expires_at", nullable = false)
    LocalDateTime expiresAt;

    @Column(name = "resolved_at")
    LocalDateTime resolvedAt;
}
