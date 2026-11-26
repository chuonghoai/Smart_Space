package com.vn.smart_space.controller.news;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.news.NewsCreateRequest;
import com.vn.smart_space.dto.request.news.NewsUpdateRequest;
import com.vn.smart_space.dto.response.news.NewsResponse;
import com.vn.smart_space.service.news.INewsService;

import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/news")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class NewsController {

    INewsService newsService;

    @GetMapping
    public ResponseEntity<ApiResponse> getAllNews() {
        List<NewsResponse> list = newsService.getAllNews();
        return ResponseEntity.ok(ApiResponse.success("news.get_all.success", list));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse> getNewsDetail(@PathVariable String id) {
        NewsResponse news = newsService.getNewsDetail(id);
        return ResponseEntity.ok(ApiResponse.success("news.get_detail.success", news));
    }

    @PostMapping
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> createNews(
            @Valid @RequestBody NewsCreateRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        NewsResponse created = newsService.createNews(request, adminId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("news.create.success", created));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> updateNews(
            @PathVariable String id,
            @Valid @RequestBody NewsUpdateRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        NewsResponse updated = newsService.updateNews(id, request, adminId);
        return ResponseEntity.ok(ApiResponse.success("news.update.success", updated));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> deleteNews(
            @PathVariable String id,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        newsService.deleteNews(id, adminId);
        return ResponseEntity.ok(ApiResponse.success("news.delete.success", null));
    }
}
