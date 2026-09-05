package com.vn.smart_space.dto.request.user;

import java.time.LocalDate;

import com.vn.smart_space.consts.EGender;

import jakarta.validation.constraints.NotBlank;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.Setter;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@FieldDefaults(level = AccessLevel.PRIVATE)
public class UpdateProfileRequest {

    @NotBlank(message = "Full name is required")
    String fullName;

    String phone;

    String avatarUrl;

    LocalDate dateOfBirth;
    EGender gender;

}
