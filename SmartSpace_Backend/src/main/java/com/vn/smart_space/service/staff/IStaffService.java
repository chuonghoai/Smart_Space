package com.vn.smart_space.service.staff;

import com.vn.smart_space.dto.request.admin.CreateStaffRequest;
import com.vn.smart_space.dto.request.admin.UpdateStaffRequest;
import com.vn.smart_space.dto.request.admin.UpdateStaffStatusRequest;
import com.vn.smart_space.dto.response.admin.StaffListResponse;
import com.vn.smart_space.dto.response.admin.StaffResponse;
import java.util.List;

public interface IStaffService {
    List<StaffResponse> getStaffs();

    StaffListResponse getStaffsPaged(int page, int size, String search, String status);

    void updateStaffStatus(String id, UpdateStaffStatusRequest request, String adminId);

    StaffResponse createStaff(CreateStaffRequest request, String adminId);

    StaffResponse updateStaff(String staffId, UpdateStaffRequest request, String adminId);
}
