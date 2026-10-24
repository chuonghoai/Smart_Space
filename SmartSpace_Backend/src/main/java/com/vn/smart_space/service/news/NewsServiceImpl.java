package com.vn.smart_space.service.news;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.dto.request.news.NewsCreateRequest;
import com.vn.smart_space.dto.request.news.NewsUpdateRequest;
import com.vn.smart_space.dto.response.news.NewsResponse;
import com.vn.smart_space.exception.ResourceNotFoundException;
import java.util.Map;
import java.util.Objects;

import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.service.notification.IFCMService;
import com.vn.smart_space.service.notification.INotificationService;
import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.model.News;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.NewsRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.i18n.MessageService;
import org.springframework.context.MessageSource;
import java.util.Locale;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class NewsServiceImpl implements INewsService {

    NewsRepository newsRepository;
    UserRepository userRepository;
    ActivityHistoryRepository activityHistoryRepository;
    INotificationService notificationService;
    IFCMService fcmService;
    MessageSource messageSource;
    MessageService messageService;

    @Override
    @Transactional(readOnly = true)
    public List<NewsResponse> getAllNews() {
        return newsRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public NewsResponse getNewsDetail(String id) {
        News news = findOrThrow(id);
        return toResponse(news);
    }

    @Override
    @Transactional
    public NewsResponse createNews(NewsCreateRequest request, String adminId) {
        User admin = adminId != null ? userRepository.findById(adminId).orElse(null) : null;
        String authorName = resolveAuthorName(admin);

        String imageUrlsStr = null;
        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            imageUrlsStr = String.join(",", request.getImageUrls());
        }

        News news = News.builder()
                .title(request.getTitle().trim())
                .content(request.getContent().trim())
                .imageUrls(imageUrlsStr)
                .author(admin)
                .authorName(authorName)
                .build();

        news = newsRepository.save(news);
        logActivity("activity.news.created", admin, news);

        if (Boolean.TRUE.equals(request.getSendNotification())) {
            sendTargetedNotifications(news, request.getTargetRoles());
        }

        return toResponse(news);
    }

    @Override
    @Transactional
    public NewsResponse updateNews(String id, NewsUpdateRequest request, String adminId) {
        News news = findOrThrow(id);
        User admin = adminId != null ? userRepository.findById(adminId).orElse(null) : null;

        String imageUrlsStr = null;
        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            imageUrlsStr = String.join(",", request.getImageUrls());
        }

        news.setTitle(request.getTitle().trim());
        news.setContent(request.getContent().trim());
        news.setImageUrls(imageUrlsStr);

        news = newsRepository.save(news);
        logActivity("activity.news.updated", admin, news);

        return toResponse(news);
    }

    @Override
    @Transactional
    public void deleteNews(String id, String adminId) {
        News news = findOrThrow(id);
        User admin = adminId != null ? userRepository.findById(adminId).orElse(null) : null;

        newsRepository.delete(news);
        logActivity("activity.news.deleted", admin, news);
    }

    private News findOrThrow(String id) {
        return newsRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("news.not_found"));
    }

    private String resolveAuthorName(User user) {
        if (user == null) {
            return messageService.get("news.default_author");
        }
        if (user.getFullName() != null && !user.getFullName().trim().isEmpty()) {
            return user.getFullName().trim();
        }
        return user.getEmail() != null ? user.getEmail() : messageService.get("news.default_author");
    }

    private NewsResponse toResponse(News news) {
        List<String> images = Collections.emptyList();
        if (news.getImageUrls() != null && !news.getImageUrls().trim().isEmpty()) {
            images = Arrays.stream(news.getImageUrls().split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.toList());
        }

        return NewsResponse.builder()
                .id(news.getId())
                .title(news.getTitle())
                .content(news.getContent())
                .imageUrls(images)
                .authorId(news.getAuthor() != null ? news.getAuthor().getId() : null)
                .authorName(news.getAuthorName() != null ? news.getAuthorName() : resolveAuthorName(news.getAuthor()))
                .authorAvatar(news.getAuthor() != null ? news.getAuthor().getAvatarUrl() : null)
                .createdAt(news.getCreatedAt())
                .updatedAt(news.getUpdatedAt())
                .build();
    }

    private void logActivity(String key, User admin, News news) {
        String adminName = admin != null && admin.getFullName() != null
                ? admin.getFullName().trim()
                : (admin != null && admin.getEmail() != null ? admin.getEmail() : messageService.get("staff.default_name"));

        ActivityHistory activity = ActivityHistory.builder()
                .actor(admin)
                .i18nKey(key + "|" + adminName + "|" + news.getTitle())
                .targetId(news.getId())
                .build();
        activityHistoryRepository.save(activity);
    }

    private void sendTargetedNotifications(News news, List<String> targetRoles) {
        if (targetRoles == null || targetRoles.isEmpty()) {
            return;
        }

        List<ERole> roles = targetRoles.stream()
                .map(r -> {
                    try {
                        return ERole.valueOf(r.trim().toLowerCase());
                    } catch (Exception e) {
                        return null;
                    }
                })
                .filter(Objects::nonNull)
                .collect(Collectors.toList());

        if (roles.isEmpty()) {
            return;
        }

        List<User> targetUsers = userRepository.findByRoleIn(roles);
        if (targetUsers == null || targetUsers.isEmpty()) {
            return;
        }

        String actionData = String.format("{\"type\": \"NEWS_DETAIL\", \"payload\": {\"newsId\": \"%s\"}}", news.getId());
        String imageUrl = null;
        if (news.getImageUrls() != null && !news.getImageUrls().trim().isEmpty()) {
            imageUrl = news.getImageUrls().split(",")[0].trim();
        }

        for (User user : targetUsers) {
            try {
                Locale userLocale = "en".equalsIgnoreCase(user.getLanguage()) ? Locale.ENGLISH : Locale.forLanguageTag("vi");
                String notifTitle = messageSource.getMessage("notification.news.new.title", null, "Tin tức mới", userLocale);
                String notifMessage = news.getTitle();

                NotificationRequest fcmRequest = new NotificationRequest(
                        notifTitle,
                        notifMessage,
                        Map.of("type", "NEWS_DETAIL", "payload", "{\"newsId\":\"" + news.getId() + "\"}")
                );

                notificationService.createNotification(user.getId(), notifTitle, notifMessage, actionData, imageUrl);
                fcmService.sendToUser(user.getId(), fcmRequest);
            } catch (Exception ignored) {
            }
        }
    }
}
