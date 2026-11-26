package com.vn.smart_space.dto.response.call;

import com.fasterxml.jackson.annotation.JsonInclude;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CallPermissionResponse {
    private boolean allowed;
    private boolean canMessage;
    private boolean isAnonymous;
    private String reasonCode;
    private String reasonMessage;
    private long eligibleRehandlingReportCount;
}
