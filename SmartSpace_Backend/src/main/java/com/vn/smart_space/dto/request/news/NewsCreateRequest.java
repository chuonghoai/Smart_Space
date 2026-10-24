package com.vn.smart_space.dto.request.news;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class NewsCreateRequest {

    @NotBlank(message = "news.title.required")
    private String title;

    @NotBlank(message = "news.content.required")
    private String content;

    @JsonProperty("image_urls")
    private List<String> imageUrls;

    @JsonProperty("send_notification")
    private Boolean sendNotification;

    @JsonProperty("target_roles")
    private List<String> targetRoles;
}
