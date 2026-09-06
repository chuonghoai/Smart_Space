package com.vn.smart_space.configuration;

import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import com.vn.smart_space.consts.EGender;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.UserRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        if (!userRepository.existsByEmail("admin@gmail.com")) {
            log.info("Khởi tạo tài khoản admin mặc định...");
            User admin = new User();
            admin.setEmail("admin@gmail.com");
            admin.setPassword(passwordEncoder.encode("Ad123456!"));
            admin.setRole(ERole.admin);
            admin.setStatus(EUserStatus.active);
            admin.setFullName("Nguyễn Văn Admin");
            admin.setGender(EGender.male);
            admin.setPhone("0901234567");
            admin.setAvatarUrl("https://ui-avatars.com/api/?name=AD&background=6366f1&color=fff&size=200&bold=true&font-size=0.4");
            
            userRepository.save(admin);
            log.info("Tạo tài khoản admin thành công (admin@gmail.com / Ad123456!)");
        }
    }
}
