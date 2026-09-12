package com.vn.smart_space.service.staff;

import com.vn.smart_space.dto.response.admin.StaffResponse;
import java.util.List;

public interface IStaffService {
    List<StaffResponse> getStaffs();
}
