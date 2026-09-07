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
    private final org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        try {
            jdbcTemplate.execute("ALTER TABLE users DROP INDEX UK6dotkott2kjsp8vw4d0m25fb7");
            log.info("Dropped legacy unique index on email");
        } catch (Exception e) {
            log.info("Legacy index might not exist or already dropped: " + e.getMessage());
        }

        try {
            jdbcTemplate.execute("UPDATE users SET language = 'vi' WHERE language IS NULL");
            log.info("Migrated existing users to default language 'vi'");
        } catch (Exception e) {
            log.warn("Failed to migrate user language: " + e.getMessage());
        }

        if (!userRepository.existsByEmailAndRole("admin@gmail.com", ERole.admin)) {
            log.info("Khởi tạo tài khoản admin mặc định...");
            User admin = new User();
            admin.setEmail("admin@gmail.com");
            admin.setPassword(passwordEncoder.encode("Ad123456!"));
            admin.setRole(ERole.admin);
            admin.setStatus(EUserStatus.active);
            admin.setFullName("Nguyễn Văn Admin");
            admin.setGender(EGender.male);
            admin.setPhone("0901234567");
            admin.setLanguage("vi");
            admin.setAvatarUrl("https://ui-avatars.com/api/?name=AD&background=6366f1&color=fff&size=200&bold=true&font-size=0.4");
            
            userRepository.save(admin);
            log.info("Tạo tài khoản admin thành công (admin@gmail.com / Ad123456!)");
        }
    }
}
