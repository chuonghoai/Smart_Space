package com.vn.smart_space.configuration.redis;

import io.lettuce.core.ClientOptions;
import io.lettuce.core.SocketOptions;
import io.lettuce.core.TimeoutOptions;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.event.EventListener;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.connection.RedisPassword;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.util.StringUtils;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Locale;

@Configuration
public class RedisConfig {

    private static final Logger log = LoggerFactory.getLogger(RedisConfig.class);
    private static final int DEFAULT_REDIS_PORT = 6379;
    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(5);
    private static final Duration COMMAND_TIMEOUT = Duration.ofSeconds(5);
    private static final Duration SHUTDOWN_TIMEOUT = Duration.ofMillis(200);

    @Value("${spring.data.redis.url:redis://localhost:6379}")
    private String redisUrl;

    @Bean
    public LettuceConnectionFactory redisConnectionFactory() {
        ResolvedRedisSettings settings = parseRedisUrl(redisUrl);

        log.info(
                "Initializing Redis connection factory [tls={}, host={}, port={}, database={}]",
                settings.tls(),
                settings.host(),
                settings.port(),
                settings.database()
        );

        LettuceClientConfiguration clientConfig = buildClientConfiguration(settings.tls());
        return new LettuceConnectionFactory(settings.standaloneConfiguration(), clientConfig);
    }

    @Bean
    public StringRedisTemplate stringRedisTemplate(LettuceConnectionFactory connectionFactory) {
        return new StringRedisTemplate(connectionFactory);
    }

    @EventListener(ApplicationReadyEvent.class)
    public void verifyRedisConnectionOnStartup(ApplicationReadyEvent event) {
        ResolvedRedisSettings settings = parseRedisUrl(redisUrl);
        LettuceConnectionFactory connectionFactory = event.getApplicationContext().getBean(LettuceConnectionFactory.class);
        try (RedisConnection connection = connectionFactory.getConnection()) {
            String pong = connection.ping();
            log.info(
                    "Redis connection ready [tls={}, host={}, port={}, ping={}]",
                    settings.tls(),
                    settings.host(),
                    settings.port(),
                    pong
            );
        } catch (Exception ex) {
            log.warn(
                    "Redis connection check failed on startup [tls={}, host={}, port={}, errorType={}]",
                    settings.tls(),
                    settings.host(),
                    settings.port(),
                    ex.getClass().getSimpleName()
            );
        }
    }

    static LettuceClientConfiguration buildClientConfiguration(boolean useTls) {
        SocketOptions socketOptions = SocketOptions.builder()
                .connectTimeout(CONNECT_TIMEOUT)
                .keepAlive(true)
                .build();

        ClientOptions clientOptions = ClientOptions.builder()
                .socketOptions(socketOptions)
                .timeoutOptions(TimeoutOptions.enabled())
                .autoReconnect(true)
                .build();

        LettuceClientConfiguration.LettuceClientConfigurationBuilder builder = LettuceClientConfiguration.builder()
                .clientOptions(clientOptions)
                .commandTimeout(COMMAND_TIMEOUT)
                .shutdownTimeout(SHUTDOWN_TIMEOUT);

        if (useTls) {
            // Keep default JVM peer verification enabled for Aiven rediss:// / valkeys:// connections.
            builder.useSsl();
        }

        return builder.build();
    }

    static ResolvedRedisSettings parseRedisUrl(String rawUrl) {
        if (!StringUtils.hasText(rawUrl)) {
            throw new IllegalArgumentException("REDIS_URL must not be blank");
        }

        URI uri;
        try {
            uri = URI.create(rawUrl.trim());
        } catch (IllegalArgumentException ex) {
            // Never include rawUrl in exception messages because it may contain credentials.
            throw new IllegalArgumentException("Invalid REDIS_URL syntax");
        }

        String scheme = uri.getScheme() == null ? "" : uri.getScheme().toLowerCase(Locale.ROOT);
        boolean tls;
        switch (scheme) {
            case "rediss", "valkeys" -> tls = true;
            case "redis", "valkey" -> tls = false;
            default -> throw new IllegalArgumentException(
                    "Unsupported REDIS_URL scheme '" + scheme + "'. Expected redis, rediss, valkey, or valkeys"
            );
        }

        String host = uri.getHost();
        if (!StringUtils.hasText(host)) {
            throw new IllegalArgumentException("Invalid REDIS_URL: missing host");
        }

        int port = uri.getPort() > 0 ? uri.getPort() : DEFAULT_REDIS_PORT;
        int database = parseDatabaseIndex(uri.getPath());

        RedisStandaloneConfiguration standalone = new RedisStandaloneConfiguration(host, port);
        standalone.setDatabase(database);
        applyCredentials(standalone, uri.getRawUserInfo());

        return new ResolvedRedisSettings(tls, host, port, database, standalone);
    }

    private static int parseDatabaseIndex(String path) {
        if (!StringUtils.hasText(path) || "/".equals(path)) {
            return 0;
        }
        String trimmed = path.startsWith("/") ? path.substring(1) : path;
        if (trimmed.contains("/")) {
            throw new IllegalArgumentException("Invalid REDIS_URL: invalid database path");
        }
        try {
            int db = Integer.parseInt(trimmed);
            if (db < 0) {
                throw new IllegalArgumentException("Invalid REDIS_URL: database index must be >= 0");
            }
            return db;
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException("Invalid REDIS_URL: invalid database index");
        }
    }

    private static void applyCredentials(RedisStandaloneConfiguration standalone, String rawUserInfo) {
        if (!StringUtils.hasText(rawUserInfo)) {
            return;
        }
        int colonIndex = rawUserInfo.indexOf(':');
        if (colonIndex >= 0) {
            String rawUser = rawUserInfo.substring(0, colonIndex);
            String rawPassword = rawUserInfo.substring(colonIndex + 1);
            if (StringUtils.hasText(rawUser)) {
                standalone.setUsername(percentDecode(rawUser));
            }
            if (StringUtils.hasText(rawPassword)) {
                standalone.setPassword(RedisPassword.of(percentDecode(rawPassword)));
            }
        } else {
            standalone.setPassword(RedisPassword.of(percentDecode(rawUserInfo)));
        }
    }

    private static String percentDecode(String value) {
        return URLDecoder.decode(value.replace("+", "%2B"), StandardCharsets.UTF_8);
    }

    record ResolvedRedisSettings(
            boolean tls,
            String host,
            int port,
            int database,
            RedisStandaloneConfiguration standaloneConfiguration
    ) {
    }
}
