package com.vn.smart_space.dto.request.media;

import jakarta.validation.constraints.NotBlank;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MediaConfirmRequest {
    @NotBlank(message = "{media.publicId.required}")
    private String publicId;
    @NotBlank(message = "{media.secureUrl.required}")
    private String secureUrl;
    @NotBlank(message = "{media.resourceType.required}")
    private String resourceType; // "image"
}
