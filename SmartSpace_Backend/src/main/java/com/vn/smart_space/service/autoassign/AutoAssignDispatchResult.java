package com.vn.smart_space.service.autoassign;

import com.vn.smart_space.consts.EAutoAssignMode;
import com.vn.smart_space.model.AssignmentDecisionLog;
import com.vn.smart_space.model.User;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AutoAssignDispatchResult {

    boolean assigned;
    EAutoAssignMode mode;
    User selectedStaff;
    AssignmentDecisionLog decisionLog;
    String fallbackReason;
}
