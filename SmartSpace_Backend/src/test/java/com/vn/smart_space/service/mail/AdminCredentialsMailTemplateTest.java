package com.vn.smart_space.service.mail;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.context.support.ResourceBundleMessageSource;
import org.thymeleaf.context.Context;
import org.thymeleaf.spring6.SpringTemplateEngine;
import org.thymeleaf.templatemode.TemplateMode;
import org.thymeleaf.templateresolver.ClassLoaderTemplateResolver;

/**
 * Render template mail/admin-credentials với MessageSource thật (i18n/messages_*),
 * không cần Spring context. Đồng thời xuất file preview tại target/mail-preview/.
 */
class AdminCredentialsMailTemplateTest {

    private static SpringTemplateEngine engine;

    @BeforeAll
    static void setUp() {
        ClassLoaderTemplateResolver resolver = new ClassLoaderTemplateResolver();
        resolver.setPrefix("templates/");
        resolver.setSuffix(".html");
        resolver.setTemplateMode(TemplateMode.HTML);
        resolver.setCharacterEncoding(StandardCharsets.UTF_8.name());

        ResourceBundleMessageSource messageSource = new ResourceBundleMessageSource();
        messageSource.setBasenames("i18n/messages");
        messageSource.setDefaultEncoding(StandardCharsets.UTF_8.name());
        messageSource.setFallbackToSystemLocale(false);

        engine = new SpringTemplateEngine();
        engine.setTemplateResolver(resolver);
        engine.setTemplateEngineMessageSource(messageSource);
    }

    private static String render(Locale locale, String fullName, boolean withOptional) {
        Context ctx = new Context(locale);
        ctx.setVariable("lang", locale.getLanguage());
        ctx.setVariable("fullName", fullName);
        ctx.setVariable("email", "quantri@smartspace.vn");
        ctx.setVariable("password", "Ab3#xK9pQ2");
        ctx.setVariable("logoUrl", null);
        ctx.setVariable("adminPortalUrl", withOptional ? "https://admin.smartspace.vn" : null);
        ctx.setVariable("supportEmail", withOptional ? "support@smartspace.vn" : null);
        ctx.setVariable("year", "2026");
        return engine.process("mail/admin-credentials", ctx);
    }

    // Test Case ID: SMP-293
    // Description: Render template mail/admin-credentials tiếng Việt đầy đủ thông tin đăng nhập, nút Admin Portal, hỗ trợ và xuất HTML preview.
    @Test
    void rendersVietnameseWithAllSections() throws IOException {
        String html = render(Locale.forLanguageTag("vi"), "Trần Thị B", true);

        assertTrue(html.contains("Xin chào Trần Thị B,"));
        assertTrue(html.contains("Ab3#xK9pQ2"));
        assertTrue(html.contains("quantri@smartspace.vn"));
        assertTrue(html.contains("Mở SmartSpace Admin Portal"));
        assertTrue(html.contains("https://admin.smartspace.vn"));
        assertTrue(html.contains("mailto:support@smartspace.vn"));
        assertTrue(html.contains("© 2026 SmartSpace"));
        assertNoMissingMessages(html);

        writePreview("admin-credentials_vi.html", html);
    }

    // Test Case ID: SMP-294
    // Description: Render template mail/admin-credentials tiếng Anh, ẩn nút portal và dòng hỗ trợ khi thiếu biến tùy chọn và không nhắc tới staff.
    @Test
    void rendersEnglishAndHidesOptionalSections() throws IOException {
        String html = render(Locale.ENGLISH, "Jane Doe", false);

        assertTrue(html.contains("Hello Jane Doe,"));
        assertTrue(html.contains("Get started in 3 steps"));
        assertFalse(html.contains("Open SmartSpace Admin Portal"), "CTA must be hidden without adminPortalUrl");
        assertFalse(html.contains("mailto:"), "Support line must be hidden without supportEmail");
        assertFalse(html.toLowerCase().contains("staff"), "Admin mail must not mention the staff app");
        assertNoMissingMessages(html);

        writePreview("admin-credentials_en.html", html);
    }

    // Test Case ID: SMP-295
    // Description: Kiểm tra HTML-escape giá trị fullName chứa thẻ script trong template mail/admin-credentials để phòng chống XSS.
    @Test
    void escapesUserProvidedValues() {
        String html = render(Locale.forLanguageTag("vi"), "<script>alert(1)</script>", false);

        assertFalse(html.contains("<script>alert(1)</script>"));
        assertTrue(html.contains("&lt;script&gt;"));
    }

    /** Thymeleaf render key thiếu dạng "??key_locale??". */
    private static void assertNoMissingMessages(String html) {
        assertFalse(html.contains("??"), "Template references a missing i18n key");
    }

    private static void writePreview(String fileName, String html) throws IOException {
        Path dir = Path.of("target", "mail-preview");
        Files.createDirectories(dir);
        Files.writeString(dir.resolve(fileName), html, StandardCharsets.UTF_8);
    }
}
