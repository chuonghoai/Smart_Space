package com.vn.smart_space.dto.response.call;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.vn.smart_space.consts.ERole;

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
public class CallPeerResponse {
    private String id;
    private String fullName;
    private String avatarUrl;
    private ERole role;
    private String position;
    private Boolean isAnonymous;
}
