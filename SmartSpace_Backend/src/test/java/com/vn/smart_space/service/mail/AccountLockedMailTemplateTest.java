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

/** Render template mail/account-locked với MessageSource thật; xuất preview tại target/mail-preview/. */
class AccountLockedMailTemplateTest {

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

    private static String render(Locale locale, String fullName, String reason, boolean withSupport) {
        Context ctx = new Context(locale);
        ctx.setVariable("lang", locale.getLanguage());
        ctx.setVariable("fullName", fullName);
        ctx.setVariable("reason", reason);
        ctx.setVariable("logoUrl", null);
        ctx.setVariable("supportEmail", withSupport ? "support@smartspace.vn" : null);
        ctx.setVariable("year", "2026");
        return engine.process("mail/account-locked", ctx);
    }

    // Test Case ID: SMP-290
    // Description: Render template mail/account-locked tiếng Việt kèm lý do khóa, email hỗ trợ, không thiếu key i18n và xuất HTML preview.
    @Test
    void rendersVietnameseWithReason() throws IOException {
        String html = render(Locale.forLanguageTag("vi"), "Lê Văn C", "Đăng nhiều phản ánh sai sự thật.", true);

        assertTrue(html.contains("Xin chào Lê Văn C,"));
        assertTrue(html.contains("Đăng nhiều phản ánh sai sự thật."));
        assertTrue(html.contains("Hội đồng quản trị"));
        assertTrue(html.contains("mailto:support@smartspace.vn"));
        assertTrue(html.contains("© 2026 SmartSpace"));
        assertFalse(html.contains("??"), "Template references a missing i18n key");

        Path dir = Path.of("target", "mail-preview");
        Files.createDirectories(dir);
        Files.writeString(dir.resolve("account-locked_vi.html"), html, StandardCharsets.UTF_8);
    }

    // Test Case ID: SMP-291
    // Description: Render template mail/account-locked tiếng Anh và ẩn dòng liên hệ hỗ trợ khi supportEmail là null.
    @Test
    void rendersEnglishAndHidesSupportLine() {
        String html = render(Locale.ENGLISH, "Jane Doe", "Repeated spam reports.", false);

        assertTrue(html.contains("Hello Jane Doe,"));
        assertTrue(html.contains("Repeated spam reports."));
        assertFalse(html.contains("mailto:"));
        assertFalse(html.contains("??"));
    }

    // Test Case ID: SMP-292
    // Description: Kiểm tra HTML-escape cho fullName và reason chứa thẻ HTML/script trong template mail/account-locked để chống XSS.
    @Test
    void escapesReasonAndName() {
        String html = render(Locale.forLanguageTag("vi"), "<b>x</b>", "<script>alert(1)</script>", false);

        assertFalse(html.contains("<script>alert(1)</script>"));
        assertTrue(html.contains("&lt;script&gt;"));
        assertFalse(html.contains("<b>x</b>"));
    }
}
