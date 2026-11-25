package com.vn.smart_space.dto.request.emergency;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.vn.smart_space.consts.EEmergencyRelationship;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
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
public class EmergencyContactRequest {

    @NotBlank(message = "emergency_contact.name.required")
    @Size(max = 100, message = "emergency_contact.name.too_long")
    String name;

    @NotBlank(message = "emergency_contact.phone.required")
    @Size(max = 20, message = "emergency_contact.phone.invalid")
    String phone;

    @NotNull(message = "emergency_contact.relationship.required")
    EEmergencyRelationship relationship;

    /** Email tài khoản SmartSpace của người quen (tuỳ chọn) để liên kết và nhận push. */
    @Email(message = "emergency_contact.account_email.invalid")
    @Size(max = 255, message = "emergency_contact.account_email.invalid")
    @JsonProperty("account_email")
    String accountEmail;

    /** Bắt buộc true khi không liên kết tài khoản: owner xác nhận người quen đã đồng ý nhận SMS khẩn cấp. */
    @JsonProperty("consent_confirmed")
    Boolean consentConfirmed;
}
