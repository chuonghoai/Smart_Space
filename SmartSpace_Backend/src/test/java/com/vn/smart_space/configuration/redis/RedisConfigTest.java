package com.vn.smart_space.configuration.redis;

import io.lettuce.core.ClientOptions;
import io.lettuce.core.SslVerifyMode;
import org.junit.jupiter.api.Test;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RedisConfigTest {

    // Test Case ID: SMP-164
    // Description: Kiểm tra parseRedisUrl phân tích URL rediss:// gồm host, port, username, password và bật TLS
    @Test
    void parseRedisUrl_withRedissUrl_parsesHostPortCredentialsAndEnablesTls() {
        RedisConfig.ResolvedRedisSettings settings = RedisConfig.parseRedisUrl(
                "rediss://default:super-secret@valkey-prod.aivencloud.com:25061"
        );

        assertTrue(settings.tls());
        assertEquals("valkey-prod.aivencloud.com", settings.host());
        assertEquals(25061, settings.port());
        assertEquals(0, settings.database());

        RedisStandaloneConfiguration standalone = settings.standaloneConfiguration();
        assertEquals("valkey-prod.aivencloud.com", standalone.getHostName());
        assertEquals(25061, standalone.getPort());
        assertEquals("default", standalone.getUsername());
        assertEquals("super-secret", new String(standalone.getPassword().get()));
    }

    // Test Case ID: SMP-165
    // Description: Kiểm tra parseRedisUrl xử lý URL valkeys:// có mật khẩu URL-encoded, giữ nguyên dấu '+' thô và database index
    @Test
    void parseRedisUrl_withValkeysUrlEncodedPasswordAndDb_preservesPlusAndDecodes() {
        RedisConfig.ResolvedRedisSettings settings = RedisConfig.parseRedisUrl(
                "valkeys://svc_user:p%40ss%2Bw0rd+raw@valkey.internal:26379/3"
        );

        assertTrue(settings.tls());
        assertEquals(3, settings.database());
        RedisStandaloneConfiguration standalone = settings.standaloneConfiguration();
        assertEquals("svc_user", standalone.getUsername());
        assertEquals("p@ss+w0rd+raw", new String(standalone.getPassword().get()));
        assertEquals(3, standalone.getDatabase());
    }

    // Test Case ID: SMP-166
    // Description: Kiểm tra parseRedisUrl với URL redis://localhost:6379 tắt TLS và ánh xạ đúng host, port
    @Test
    void parseRedisUrl_withLocalRedisUrl_disablesTls() {
        RedisConfig.ResolvedRedisSettings settings = RedisConfig.parseRedisUrl(
                "redis://localhost:6379"
        );

        assertFalse(settings.tls());
        assertEquals("localhost", settings.host());
        assertEquals(6379, settings.port());
        assertEquals("localhost", settings.standaloneConfiguration().getHostName());
        assertEquals(6379, settings.standaloneConfiguration().getPort());
    }

    // Test Case ID: SMP-167
    // Description: Kiểm tra parseRedisUrl với URL redis:// không chỉ định port sẽ dùng port mặc định 6379
    @Test
    void parseRedisUrl_withRedisPlainUrlAndDefaultPort_usesPort6379() {
        RedisConfig.ResolvedRedisSettings settings = RedisConfig.parseRedisUrl(
                "redis://cache.local"
        );

        assertFalse(settings.tls());
        assertEquals("cache.local", settings.host());
        assertEquals(6379, settings.port());
    }

    // Test Case ID: SMP-168
    // Description: Kiểm tra parseRedisUrl ném IllegalArgumentException khi URL rỗng/null/sai scheme/sai cú pháp và không lộ mật khẩu
    @Test
    void parseRedisUrl_whenBlankOrInvalid_throwsWithoutLeakingCredentials() {
        assertThrows(IllegalArgumentException.class, () -> RedisConfig.parseRedisUrl("   "));
        assertThrows(IllegalArgumentException.class, () -> RedisConfig.parseRedisUrl(null));

        String secret = "verySensitiveSecret123";
        IllegalArgumentException unsupported = assertThrows(
                IllegalArgumentException.class,
                () -> RedisConfig.parseRedisUrl("http://default:" + secret + "@bad-host:6379")
        );
        assertFalse(unsupported.getMessage().contains(secret));

        IllegalArgumentException malformed = assertThrows(
                IllegalArgumentException.class,
                () -> RedisConfig.parseRedisUrl("rediss://default:" + secret + "@bad host:6379")
        );
        assertFalse(malformed.getMessage().contains(secret));
    }

    // Test Case ID: SMP-169
    // Description: Kiểm tra buildClientConfiguration cấu hình SSL FULL, autoReconnect và keepAlive khi bật/tắt TLS
    @Test
    void buildClientConfiguration_configuresSslVerificationAndReconnectOptions() {
        LettuceClientConfiguration tlsConfig = RedisConfig.buildClientConfiguration(true);
        assertTrue(tlsConfig.isUseSsl());
        assertEquals(SslVerifyMode.FULL, tlsConfig.getVerifyMode());
        ClientOptions clientOptions = tlsConfig.getClientOptions().orElseThrow();
        assertTrue(clientOptions.isAutoReconnect());
        assertTrue(clientOptions.getSocketOptions().isKeepAlive());

        LettuceClientConfiguration localConfig = RedisConfig.buildClientConfiguration(false);
        assertFalse(localConfig.isUseSsl());
    }
}
