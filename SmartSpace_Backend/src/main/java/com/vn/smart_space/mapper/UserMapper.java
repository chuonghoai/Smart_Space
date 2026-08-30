package com.vn.smart_space.mapper;

import org.mapstruct.Mapper;

import com.vn.smart_space.consts.ERegistrationStatus;
import com.vn.smart_space.dto.response.user.UserResponse;
import com.vn.smart_space.model.User;

@Mapper(componentModel = "spring")
public interface UserMapper {

    @org.mapstruct.Mapping(target = "registrationStatus", expression = "java(determineRegistrationStatus(user))")
    UserResponse toUserResponse(User user);

    default ERegistrationStatus determineRegistrationStatus(User user) {
        if (user.getPhone() != null && !user.getPhone().isBlank()
            && user.getFullName() != null && !user.getFullName().isBlank()) {
            return ERegistrationStatus.complete;
        }
        return ERegistrationStatus.incomplete;
    }
}
