package com.vn.smart_space.dto.request.admin;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Phiếu biểu quyết */
public record AccountLockVoteRequest(
                @NotBlank(message = "{lock_request.vote.decision_invalid}") String decision,

                @Size(max = 500, message = "{lock_request.vote.comment_too_long}") String comment) {
}
