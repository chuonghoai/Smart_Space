package com.vn.smart_space.service.call;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;
import java.util.Map;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vn.smart_space.dto.response.call.IceServerConfigResponse;
import com.vn.smart_space.dto.response.call.IceServerDto;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j(topic = "TURN-CREDENTIAL-SERVICE")
public class TurnCredentialService {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();

    @Value("${webrtc.stun-urls:stun:stun.l.google.com:19302,stun:stun1.l.google.com:19302}")
    private String stunUrlsRaw;

    @Value("${webrtc.turn.mode:stun_only}")
    private String turnMode;

    @Value("${webrtc.turn.urls:}")
    private String turnUrlsRaw;

    @Value("${webrtc.turn.shared-secret:}")
    private String turnSharedSecret;

    @Value("${webrtc.turn.ttl-seconds:43200}")
    private long turnTtlSeconds;

    @Value("${webrtc.turn.username:}")
    private String staticTurnUsername;

    @Value("${webrtc.turn.credential:}")
    private String staticTurnCredential;

    @Value("${webrtc.turn.cloudflare-token-id:}")
    private String cloudflareTokenId;

    @Value("${webrtc.turn.cloudflare-api-token:}")
    private String cloudflareApiToken;

    public IceServerConfigResponse buildIceServersForUser(String userId) {
        List<IceServerDto> servers = new ArrayList<>();
        List<String> stunUrls = splitUrls(stunUrlsRaw);
        if (!stunUrls.isEmpty()) {
            servers.add(IceServerDto.builder().urls(stunUrls).build());
        }

        String normalizedMode = turnMode != null ? turnMode.trim().toLowerCase() : "stun_only";
        boolean turnConfigured = false;
        long effectiveTtl = Math.max(60, turnTtlSeconds);

        switch (normalizedMode) {
            case "coturn_hmac" -> {
                List<String> turnUrls = splitUrls(turnUrlsRaw);
                if (!turnUrls.isEmpty() && turnSharedSecret != null && !turnSharedSecret.isBlank()) {
                    long expiryEpoch = Instant.now().getEpochSecond() + effectiveTtl;
                    String username = expiryEpoch + ":" + (userId != null ? userId : "smartspace");
                    String credential = computeHmacSha1Base64(username, turnSharedSecret.trim());
                    servers.add(IceServerDto.builder()
                            .urls(turnUrls)
                            .username(username)
                            .credential(credential)
                            .build());
                    turnConfigured = true;
                } else {
                    log.warn("WEBRTC_TURN_MODE is coturn_hmac but WEBRTC_TURN_URLS or WEBRTC_TURN_SHARED_SECRET is missing");
                }
            }
            case "cloudflare" -> {
                if (cloudflareTokenId != null && !cloudflareTokenId.isBlank()
                        && cloudflareApiToken != null && !cloudflareApiToken.isBlank()) {
                    List<IceServerDto> cfServers = fetchCloudflareTurnServers(effectiveTtl);
                    if (!cfServers.isEmpty()) {
                        servers.addAll(cfServers);
                        turnConfigured = true;
                    }
                } else {
                    log.warn("WEBRTC_TURN_MODE is cloudflare but token ID / API token is missing");
                }
            }
            case "static_env" -> {
                List<String> turnUrls = splitUrls(turnUrlsRaw);
                if (!turnUrls.isEmpty() && staticTurnUsername != null && !staticTurnUsername.isBlank()
                        && staticTurnCredential != null && !staticTurnCredential.isBlank()) {
                    servers.add(IceServerDto.builder()
                            .urls(turnUrls)
                            .username(staticTurnUsername.trim())
                            .credential(staticTurnCredential.trim())
                            .build());
                    turnConfigured = true;
                } else {
                    log.warn("WEBRTC_TURN_MODE is static_env but TURN urls/username/credential are incomplete");
                }
            }
            default -> {
                // stun_only: only STUN servers are returned
            }
        }

        return IceServerConfigResponse.builder()
                .iceServers(servers)
                .mode(normalizedMode)
                .turnConfigured(turnConfigured)
                .ttlSeconds(effectiveTtl)
                .build();
    }

    private List<IceServerDto> fetchCloudflareTurnServers(long ttlSeconds) {
        try {
            String url = "https://rtc.live.cloudflare.com/v1/turn/keys/"
                    + cloudflareTokenId.trim()
                    + "/credentials/generate-ice-servers";
            String body = "{\"ttl\":" + ttlSeconds + "}";
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofSeconds(5))
                    .header("Authorization", "Bearer " + cloudflareApiToken.trim())
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 200 && response.statusCode() < 300 && response.body() != null) {
                Map<String, Object> parsed = objectMapper.readValue(response.body(), new TypeReference<>() {});
                Object rawIceServers = parsed.get("iceServers");
                if (rawIceServers != null) {
                    return objectMapper.convertValue(rawIceServers, new TypeReference<List<IceServerDto>>() {});
                }
            } else {
                log.warn("Cloudflare TURN API returned status {}: {}", response.statusCode(), response.body());
            }
        } catch (Exception e) {
            log.warn("Failed to fetch Cloudflare TURN credentials, falling back to STUN only: {}", e.getMessage());
        }
        return List.of();
    }

    private String computeHmacSha1Base64(String data, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA1");
            SecretKeySpec keySpec = new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA1");
            mac.init(keySpec);
            byte[] rawHmac = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(rawHmac);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to compute TURN HMAC-SHA1 credential", e);
        }
    }

    private List<String> splitUrls(String raw) {
        if (raw == null || raw.isBlank()) {
            return List.of();
        }
        return Arrays.stream(raw.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
    }
}
