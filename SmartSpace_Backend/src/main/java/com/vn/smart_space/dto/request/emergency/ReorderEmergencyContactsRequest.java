package com.vn.smart_space.dto.request.emergency;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.validation.constraints.NotEmpty;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ReorderEmergencyContactsRequest {

    /** Toàn bộ id liên hệ của owner theo thứ tự ưu tiên mới. */
    @NotEmpty(message = "emergency_contact.order.invalid")
    @JsonProperty("contact_ids")
    List<String> contactIds;
}
