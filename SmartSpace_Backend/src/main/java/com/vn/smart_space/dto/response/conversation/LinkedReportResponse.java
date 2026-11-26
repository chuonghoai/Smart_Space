package com.vn.smart_space.dto.response.conversation;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.io.Serializable;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class LinkedReportResponse implements Serializable {
    private String id;
    private String title;
    private String description;
    private String imageUrl;
    private String status;
    private String severity;
    private String createdAt;
    private String address;
    private Boolean isReviewResolved;
    private Boolean needsRehandling;
}

