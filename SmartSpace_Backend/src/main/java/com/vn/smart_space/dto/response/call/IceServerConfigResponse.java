package com.vn.smart_space.dto.response.call;

import java.util.List;

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
public class IceServerConfigResponse {
    private List<IceServerDto> iceServers;
    private String mode;
    private boolean turnConfigured;
    private long ttlSeconds;
}
