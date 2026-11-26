package com.vn.smart_space.configuration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import com.vn.smart_space.consts.EAutoAssignMode;
import com.vn.smart_space.consts.EGender;
import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.model.AutoAssignConfig;
import com.vn.smart_space.model.ReportCategory;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.AutoAssignConfigRepository;
import com.vn.smart_space.repository.ReportCategoryRepository;
import com.vn.smart_space.repository.UserRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final ReportCategoryRepository reportCategoryRepository;
    private final AutoAssignConfigRepository autoAssignConfigRepository;
    private final PasswordEncoder passwordEncoder;
    private final org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    @Value("${PW_ADMIN_EMAIL:admin@gmail.com}")
    private String defaultAdminEmail;

    @Value("${PW_ADMIN_PASSWORD:Ad123456!}")
    private String defaultAdminPassword;

    @Value("${PW_STAFF_EMAIL:staff1@gmail.com}")
    private String defaultStaffEmail;

    @Value("${PW_STAFF_PASSWORD:Ad123456!}")
    private String defaultStaffPassword;

    @Value("${PW_CLIENT_EMAIL:user@gmail.com}")
    private String defaultClientEmail;

    @Value("${PW_CLIENT_PASSWORD:Ad123456!}")
    private String defaultClientPassword;

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

        // Cleanup obsolete staff wallet & commission tables/columns
        String[] cleanupQueries = {
            "DROP TABLE IF EXISTS staff_wallet_transactions",
            "DROP TABLE IF EXISTS staff_withdrawal_requests",
            "DROP TABLE IF EXISTS staff_wallets",
            "DROP TABLE IF EXISTS staff_bank_accounts",
            "DROP TABLE IF EXISTS wallet_configs",
            "ALTER TABLE reports DROP COLUMN base_commission",
            "ALTER TABLE reports DROP COLUMN total_commission_deducted",
            "ALTER TABLE reports DROP COLUMN rehandling_penalty_count",
            "ALTER TABLE reports DROP COLUMN commission_awarded",
            "ALTER TABLE report_delegations DROP COLUMN rate_percent",
            "ALTER TABLE report_delegations DROP COLUMN commission_amount",
            "ALTER TABLE report_delegations DROP COLUMN bonus_amount",
            "ALTER TABLE chat_messages MODIFY COLUMN sender_id VARCHAR(255) NULL"
        };
        for (String sql : cleanupQueries) {
            try {
                jdbcTemplate.execute(sql);
            } catch (Exception ignored) {
                // Column/table already removed
            }
        }

        seedDefaultAccount(
                defaultAdminEmail,
                defaultAdminPassword,
                ERole.admin,
                "Nguyễn Văn Admin",
                EGender.male,
                "0901234567",
                "https://ui-avatars.com/api/?name=AD&background=6366f1&color=fff&size=200&bold=true&font-size=0.4");
        seedDefaultAccount(
                defaultStaffEmail,
                defaultStaffPassword,
                ERole.staff,
                "Nguyễn Văn Nhân Viên",
                EGender.male,
                "0934567890",
                "https://ui-avatars.com/api/?name=ST&background=0284c7&color=fff&size=200&bold=true&font-size=0.4");
        seedDefaultAccount(
                defaultClientEmail,
                defaultClientPassword,
                ERole.client,
                "Trần Thị User",
                EGender.female,
                "0912345678",
                "https://ui-avatars.com/api/?name=US&background=10b981&color=fff&size=200&bold=true&font-size=0.4");

        seedDefaultCategories();
        seedDefaultAutoAssignConfig();
    }

    private void seedDefaultAutoAssignConfig() {
        if (autoAssignConfigRepository.count() > 0) {
            return;
        }
        autoAssignConfigRepository.save(AutoAssignConfig.builder()
                .mode(EAutoAssignMode.ASSIST)
                .distanceWeight(0.45)
                .monthlyWorkloadWeight(0.35)
                .activeLoadWeight(0.15)
                .onTimeRateWeight(0.05)
                .maxRadiusKm(15.0)
                .maxConcurrentTasks(10)
                .targetMonthlyTasks(20)
                .build());
        log.info("Seeded default auto-assign config");
    }

    private void seedDefaultCategories() {
        if (reportCategoryRepository.count() > 0) {
            return;
        }
        seedCategory("ENVIRONMENT", "Môi trường & Rác thải", "Environment & Waste", "eco", EReportSeverity.medium, 1);
        seedCategory("INFRASTRUCTURE", "Hạ tầng & Đường bộ", "Infrastructure & Roads", "construction",
                EReportSeverity.high, 2);
        seedCategory("LIGHTING_ELECTRIC", "Chiếu sáng & Điện", "Lighting & Electricity", "bolt",
                EReportSeverity.high, 3);
        seedCategory("WATER_DRAINAGE", "Cấp thoát nước & Ngập úng", "Water & Drainage", "water_drop",
                EReportSeverity.high, 4);
        seedCategory("PUBLIC_ORDER", "Trật tự & An toàn công cộng", "Public Order & Safety", "shield",
                EReportSeverity.medium, 5);
        log.info("Seeded default report categories");
    }

    private void seedCategory(
            String code,
            String nameVi,
            String nameEn,
            String iconKey,
            EReportSeverity defaultSeverity,
            int displayOrder) {
        if (reportCategoryRepository.existsByCodeIgnoreCase(code)) {
            return;
        }
        ReportCategory category = ReportCategory.builder()
                .code(code)
                .nameVi(nameVi)
                .nameEn(nameEn)
                .iconKey(iconKey)
                .defaultSeverity(defaultSeverity)
                .isActive(true)
                .displayOrder(displayOrder)
                .build();
        reportCategoryRepository.save(category);
    }

    private void seedDefaultAccount(
            String email,
            String rawPassword,
            ERole role,
            String fullName,
            EGender gender,
            String phone,
            String avatarUrl) {
        if (email == null || email.isBlank() || rawPassword == null || rawPassword.isBlank()) {
            return;
        }
        String normalizedEmail = email.trim();
        if (!userRepository.existsByEmailAndRole(normalizedEmail, role)) {
            log.info("Khởi tạo tài khoản {} mặc định ({})...", role, normalizedEmail);
            User user = new User();
            user.setEmail(normalizedEmail);
            user.setPassword(passwordEncoder.encode(rawPassword));
            user.setRole(role);
            user.setStatus(EUserStatus.active);
            user.setFullName(fullName);
            user.setGender(gender);
            user.setPhone(phone);
            user.setLanguage("vi");
            user.setAvatarUrl(avatarUrl);
            userRepository.save(user);
            log.info("Tạo tài khoản {} mặc định thành công ({})", role, normalizedEmail);
        }
    }
}
