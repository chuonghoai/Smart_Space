package com.vn.smart_space.dto.response.admin;

import java.time.LocalDateTime;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/**
 * Đề xuất khóa tài khoản
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AccountLockRequestResponse {

    String id;
    String status; // pending | approved | rejected | cancelled | expired
    Person target;
    Person proposer;
    String reason;

    long approvals;
    long rejections;
    int requiredApprovals;
    int requiredRejections;

    LocalDateTime createdAt;
    LocalDateTime expiresAt;
    LocalDateTime resolvedAt;

    /** Phiếu của admin đang xem (approve | reject) — null nếu chưa bỏ phiếu. */
    String myVote;
    /** Admin đang xem là người đề xuất. */
    boolean mine;
    boolean canVote;
    /**
     * Lý do không được bỏ phiếu: proposer | already_voted | closed — null khi được
     * phép.
     */
    String voteBlockedReason;
    boolean canCancel;

    List<Evidence> evidences;
    List<Vote> votes;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class Person {
        String id;
        String fullName;
        String email;
        String avatarUrl;
        String status;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public static class Evidence {
        String id;
        String type; // image | report
        String imageUrl;
        String reportId;
        String reportTitle;
        String reportStatus;
        LocalDateTime reportCreatedAt;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class Vote {
        Person voter;
        String decision; // approve | reject
        String comment;
        LocalDateTime createdAt;
    }
}
