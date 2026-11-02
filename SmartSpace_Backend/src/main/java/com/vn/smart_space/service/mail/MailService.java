package com.vn.smart_space.service.mail;

import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.time.Year;
import java.util.Locale;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.MessageSource;
import org.springframework.mail.MailPreparationException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.thymeleaf.ITemplateEngine;
import org.thymeleaf.context.Context;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class MailService implements IMailService {

    private static final String STAFF_CREDENTIALS_TEMPLATE = "mail/staff-credentials";

    private final JavaMailSender mailSender;
    private final MessageSource messageSource;
    private final ITemplateEngine templateEngine;

    @Value("${spring.mail.username}")
    private String fromEmail;

    @Value("${app.mail.from-name:SmartSpace}")
    private String fromName;

    @Value("${app.mail.logo-url:}")
    private String logoUrl;

    @Value("${app.mail.staff-app-url:}")
    private String staffAppUrl;

    @Value("${app.mail.support-email:}")
    private String supportEmail;

    @Override
    public void sendOtpEmail(String toEmail, String otp) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(toEmail);
        message.setSubject("SmartSpace - Mã xác thực OTP");
        message.setText("Mã OTP của bạn là: " + otp + "\nMã có hiệu lực trong 5 phút.");
        mailSender.send(message);
    }

    @Override
    public void sendStaffCredentialsEmail(String toEmail, String fullName, String rawPassword,
            String positionName, String language) {
        Locale locale = resolveLocale(language);
        String displayName = (fullName != null && !fullName.isBlank()) ? fullName.trim() : toEmail;

        Context context = new Context(locale);
        context.setVariable("lang", locale.getLanguage());
        context.setVariable("fullName", displayName);
        context.setVariable("email", toEmail);
        context.setVariable("password", rawPassword);
        context.setVariable("positionName", blankToNull(positionName));
        context.setVariable("logoUrl", blankToNull(logoUrl));
        context.setVariable("staffAppUrl", blankToNull(staffAppUrl));
        context.setVariable("supportEmail", blankToNull(supportEmail));
        // Truyền String để MessageFormat không định dạng năm thành "2,026"
        context.setVariable("year", String.valueOf(Year.now().getValue()));

        String subject = messageSource.getMessage("mail.staff.credentials.subject", null, locale);
        String html = templateEngine.process(STAFF_CREDENTIALS_TEMPLATE, context);
        // Bản text thuần cho client không hiển thị HTML (cũng giúp giảm điểm spam)
        String plainText = messageSource.getMessage(
                "mail.staff.credentials.body",
                new Object[] { displayName, toEmail, rawPassword },
                locale);

        sendHtml(toEmail, subject, plainText, html);
    }

    /**
     * Gửi email multipart/alternative (text + HTML) với tên hiển thị người gửi.
     * Lỗi dựng message được chuyển thành {@link MailPreparationException} (một
     * {@code MailException}) để caller xử lý thống nhất với lỗi gửi.
     */
    private void sendHtml(String toEmail, String subject, String plainText, String html) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, StandardCharsets.UTF_8.name());
            helper.setFrom(fromEmail, fromName);
            helper.setTo(toEmail);
            helper.setSubject(subject);
            helper.setText(plainText, html);
            mailSender.send(mimeMessage);
        } catch (MessagingException | UnsupportedEncodingException e) {
            throw new MailPreparationException("Failed to build email for " + toEmail, e);
        }
    }

    private static Locale resolveLocale(String language) {
        return "en".equalsIgnoreCase(language) ? Locale.ENGLISH : Locale.forLanguageTag("vi");
    }

    private static String blankToNull(String value) {
        return (value == null || value.isBlank()) ? null : value.trim();
    }
}
