package com.vn.smart_space.model;

import com.vn.smart_space.consts.EAccountLockVoteDecision;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.FieldDefaults;

/** Phiếu của một admin cho một đề xuất khóa. Mỗi admin chỉ bỏ một phiếu (unique request + voter). */
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@Table(name = "account_lock_votes", uniqueConstraints = {
        @UniqueConstraint(name = "uk_lock_vote_request_voter", columnNames = { "request_id", "voter_id" })
})
public class AccountLockVote extends AbstractEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "request_id", nullable = false)
    AccountLockRequest request;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "voter_id", nullable = false)
    User voter;

    @Enumerated(EnumType.STRING)
    @Column(name = "decision", nullable = false, columnDefinition = "VARCHAR(20)")
    EAccountLockVoteDecision decision;

    @Column(name = "comment", length = 500)
    String comment;
}
