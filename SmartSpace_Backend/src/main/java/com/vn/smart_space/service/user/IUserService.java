package com.vn.smart_space.service.user;

import com.vn.smart_space.dto.request.auth.DevCreateAccountRequest;
import com.vn.smart_space.dto.request.auth.RegisterRequest;
import com.vn.smart_space.dto.request.auth.ResetPasswordRequest;
import com.vn.smart_space.dto.request.user.ChangePasswordRequest;
import com.vn.smart_space.dto.request.user.UpdateProfileRequest;
import com.vn.smart_space.dto.response.auth.LoginResponse;
import com.vn.smart_space.dto.response.user.UserResponse;
import com.vn.smart_space.model.User;

public interface IUserService {

    // Create New User
    LoginResponse createUser(RegisterRequest request);

    // Reset Password
    void resetPassword(ResetPasswordRequest request);

    // Find User By Id
    User findUserById(String id);

    // Find User By Email And Role
    User findUserByEmailAndRole(String email, com.vn.smart_space.consts.ERole role);

    // Get Me
    UserResponse getMe(String userId);

    // Update Profile
    UserResponse updateProfile(String userId, UpdateProfileRequest request);

    // Dev API: Create user directly
    void devCreateAccount(DevCreateAccountRequest request);

    // Change Password
    void changePassword(String userId, ChangePasswordRequest request);

    // Update Language
    void updateLanguage(String userId, String language);

}
