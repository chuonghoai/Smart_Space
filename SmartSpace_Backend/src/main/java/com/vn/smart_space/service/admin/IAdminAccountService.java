package com.vn.smart_space.service.admin;

import com.vn.smart_space.dto.request.admin.CreateAdminRequest;
import com.vn.smart_space.dto.request.admin.UpdateAdminStatusRequest;
import com.vn.smart_space.dto.response.admin.AdminAccountListResponse;
import com.vn.smart_space.dto.response.admin.AdminAccountResponse;

/** Quản lý tài khoản quản trị viên (mục "Hội đồng quản trị"). Mọi admin ngang quyền. */
public interface IAdminAccountService {

    AdminAccountListResponse getAdmins(int page, int size, String search, String status, String currentAdminId);

    AdminAccountResponse createAdmin(CreateAdminRequest request, String currentAdminId);

    void updateAdminStatus(String targetAdminId, UpdateAdminStatusRequest request, String currentAdminId);
}
