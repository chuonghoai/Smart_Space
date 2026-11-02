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
 * Render template mail/staff-credentials với MessageSource thật (i18n/messages_*),
 * không cần Spring context. Đồng thời xuất file preview tại target/mail-preview/.
 */
class StaffCredentialsMailTemplateTest {

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

    private static String render(Locale locale, String fullName, String positionName, boolean withOptional) {
        Context ctx = new Context(locale);
        ctx.setVariable("lang", locale.getLanguage());
        ctx.setVariable("fullName", fullName);
        ctx.setVariable("email", "nhanvien@smartspace.vn");
        ctx.setVariable("password", "Ab3#xK9pQ2");
        ctx.setVariable("positionName", positionName);
        ctx.setVariable("logoUrl", null);
        ctx.setVariable("staffAppUrl", withOptional ? "https://smartspace.vn/staff-app" : null);
        ctx.setVariable("supportEmail", withOptional ? "support@smartspace.vn" : null);
        ctx.setVariable("year", "2026");
        return engine.process("mail/staff-credentials", ctx);
    }

    @Test
    void rendersVietnameseWithAllSections() throws IOException {
        String html = render(Locale.forLanguageTag("vi"), "Nguyễn Văn A", "Kỹ thuật viên", true);

        assertTrue(html.contains("Xin chào Nguyễn Văn A,"));
        assertTrue(html.contains("Ab3#xK9pQ2"));
        assertTrue(html.contains("nhanvien@smartspace.vn"));
        assertTrue(html.contains("Kỹ thuật viên"));
        assertTrue(html.contains("Đổi mật khẩu tạm thời tại Cài đặt"));
        assertTrue(html.contains("https://smartspace.vn/staff-app"));
        assertTrue(html.contains("mailto:support@smartspace.vn"));
        assertTrue(html.contains("© 2026 SmartSpace"));
        assertNoMissingMessages(html);

        writePreview("staff-credentials_vi.html", html);
    }

    @Test
    void rendersEnglishAndHidesOptionalSections() throws IOException {
        String html = render(Locale.ENGLISH, "John Doe", null, false);

        assertTrue(html.contains("Hello John Doe,"));
        assertTrue(html.contains("Get started in 3 steps"));
        assertFalse(html.contains("Get the SmartSpace Staff app"), "CTA must be hidden without staffAppUrl");
        assertFalse(html.contains("mailto:"), "Support line must be hidden without supportEmail");
        assertFalse(html.contains(">Position<"), "Position must be hidden when null");
        assertNoMissingMessages(html);

        writePreview("staff-credentials_en.html", html);
    }

    @Test
    void escapesUserProvidedValues() {
        String html = render(Locale.forLanguageTag("vi"), "<script>alert(1)</script>", "<b>x</b>", false);

        assertFalse(html.contains("<script>alert(1)</script>"));
        assertTrue(html.contains("&lt;script&gt;"));
        assertFalse(html.contains("<b>x</b>"));
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
