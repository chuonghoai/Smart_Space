package com.vn.smart_space.service.sms;

import java.text.Normalizer;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import lombok.extern.slf4j.Slf4j;

/**
 * Gửi SMS Brandname qua eSMS (API SendMultipleMessage_V4_post_json).
 * Khi {@code app.sms.enabled=false} chỉ ghi log để chạy local/dev không tốn
 * phí.
 */
@Slf4j
@Service
public class EsmsSmsService implements ISmsService {

    private static final String SEND_PATH = "/SendMultipleMessage_V4_post_json/";
    private static final String SUCCESS_CODE = "100";

    private final boolean enabled;
    private final String apiKey;
    private final String secretKey;
    private final String brandname;
    private final String smsType;
    private final boolean sandbox;
    private final boolean unicode;
    private final RestClient restClient;

    public EsmsSmsService(
            @Value("${app.sms.enabled:false}") boolean enabled,
            @Value("${app.sms.esms.base-url:https://rest.esms.vn/MainService.svc/json}") String baseUrl,
            @Value("${app.sms.esms.api-key:}") String apiKey,
            @Value("${app.sms.esms.secret-key:}") String secretKey,
            @Value("${app.sms.esms.brandname:}") String brandname,
            @Value("${app.sms.esms.sms-type:2}") String smsType,
            @Value("${app.sms.esms.sandbox:true}") boolean sandbox,
            @Value("${app.sms.esms.unicode:false}") boolean unicode,
            @Value("${app.sms.esms.timeout-ms:10000}") int timeoutMs) {
        this.enabled = enabled;
        this.apiKey = apiKey;
        this.secretKey = secretKey;
        this.brandname = brandname;
        this.smsType = smsType;
        this.sandbox = sandbox;
        this.unicode = unicode;

        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(timeoutMs);
        factory.setReadTimeout(timeoutMs);
        this.restClient = RestClient.builder().baseUrl(baseUrl).requestFactory(factory).build();
    }

    @Override
    public boolean send(String phone, String rawContent) {
        String content = unicode ? rawContent : stripVietnameseMarks(rawContent);
        if (!enabled) {
            log.info("[SMS:disabled] to={} content={}", mask(phone), content);
            return true;
        }
        if (apiKey.isBlank() || secretKey.isBlank() || brandname.isBlank()) {
            log.error("[SMS] eSMS credentials/brandname are not configured");
            return false;
        }

        Map<String, Object> body = new HashMap<>();
        body.put("ApiKey", apiKey);
        body.put("SecretKey", secretKey);
        body.put("Phone", phone);
        body.put("Content", content);
        body.put("Brandname", brandname);
        body.put("SmsType", smsType);
        body.put("IsUnicode", unicode ? "1" : "0");
        body.put("Sandbox", sandbox ? "1" : "0");
        body.put("RequestId", UUID.randomUUID().toString());

        try {
            Map<?, ?> response = restClient.post()
                    .uri(SEND_PATH)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(Map.class);
            Object code = response != null ? response.get("CodeResult") : null;
            if (code != null && SUCCESS_CODE.equals(code.toString())) {
                return true;
            }
            log.warn("[SMS] eSMS rejected message to {}: code={} error={}", mask(phone), code,
                    response != null ? response.get("ErrorMessage") : null);
            return false;
        } catch (Exception e) {
            log.warn("[SMS] Failed to call eSMS for {}: {}", mask(phone), e.getMessage());
            return false;
        }
    }

    /** Tin không Unicode chỉ nhận ký tự GSM: bỏ dấu tiếng Việt (kể cả tên người dùng). */
    static String stripVietnameseMarks(String text) {if (text == null) {
            return "";
        }
        String decomposed = Normalizer.normalize(text, Normalizer.Form.NFD).replaceAll("\\p{M}+", "");
        return decomposed.replace('đ', 'd').replace('Đ', 'D');
    }

    private static String mask(String phone) {
        if (phone == null || phone.length() < 4) {
            return "****";
        }
        return "****" + phone.substring(phone.length() - 3);
    }
}
