package com.vn.smart_space.configuration.i18n;

import java.util.Locale;

import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.ModelAndView;

import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.UserRepository;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class UserLocaleInterceptor implements HandlerInterceptor {

    private final StringRedisTemplate stringRedisTemplate;
    private final UserRepository userRepository;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String lang = null;

        // Try to get language from authenticated user
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof Jwt jwt) {
            try {
                String userId = jwt.getClaim("userId").toString();
                String redisKey = "user_language:" + userId;
                
                // Read from Redis
                lang = stringRedisTemplate.opsForValue().get(redisKey);
                
                // If not in Redis, read from DB and cache
                if (lang == null) {
                    User user = userRepository.findById(userId).orElse(null);
                    if (user != null && user.getLanguage() != null) {
                        lang = user.getLanguage();
                        stringRedisTemplate.opsForValue().set(redisKey, lang);
                    }
                }
            } catch (Exception e) {
                log.warn("Failed to get language for authenticated user", e);
            }
        }

        // Fallback to Accept-Language header
        if (lang == null || lang.isBlank()) {
            lang = request.getHeader("Accept-Language");
        }

        // Fallback to default
        if (lang == null || lang.isBlank() || (!lang.equalsIgnoreCase("vi") && !lang.equalsIgnoreCase("en"))) {
            lang = "vi";
        } else {
            // Keep only first 2 chars just in case (e.g. en-US -> en)
            lang = lang.substring(0, 2).toLowerCase();
        }

        LocaleContextHolder.setLocale(Locale.forLanguageTag(lang));

        return true;
    }

    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView modelAndView) {
        LocaleContextHolder.resetLocaleContext();
    }
}
