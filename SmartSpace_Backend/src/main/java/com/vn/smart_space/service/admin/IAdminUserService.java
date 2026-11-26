package com.vn.smart_space.service.admin;

import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.response.admin.AdminUserDetailResponse;
import com.vn.smart_space.dto.response.admin.AdminUserResponse;
import com.vn.smart_space.dto.response.admin.AdminUserStatisticsResponse;
import com.vn.smart_space.dto.response.admin.AdminUserTrendResponse;

public interface IAdminUserService {

    PageResponse<AdminUserResponse> getUsersPaged(int page, int size, String search, String sort);

    AdminUserStatisticsResponse getStatistics();

    AdminUserTrendResponse getRegistrationTrend(String period);

    AdminUserDetailResponse getUserDetail(String userId);

}
