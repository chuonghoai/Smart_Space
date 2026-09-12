package com.vn.smart_space.service.staff;

import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.response.admin.StaffResponse;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.UserRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class StaffServiceImpl implements IStaffService {

    UserRepository userRepository;

    @Override
    public List<StaffResponse> getStaffs() {
        List<User> staffs = userRepository.findByRole(ERole.staff);
        return staffs.stream().map(s -> StaffResponse.builder()
                .id(s.getId())
                .fullName(s.getFullName())
                .email(s.getEmail())
                .phoneNumber(s.getPhone())
                .avatarUrl(s.getAvatarUrl())
                .build()
        ).collect(Collectors.toList());
    }
}
